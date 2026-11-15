#!/usr/bin/env bash
set -euo pipefail

phase=${1:?acceptance phase required}
app=raven
source_dir=$PWD
bench_dir=$(mktemp -d "${RUNNER_TEMP:?}/dinext-acceptance.XXXXXX")
site=upgrade.localhost
reports="$RUNNER_TEMP/dinext-acceptance-results"
mkdir -p "$reports"
mkdir -p "$bench_dir"/{apps,baseline,sites,logs,config}
cd "$bench_dir"

checkout() {
  local repository=$1 revision=$2 directory=$3
  git init -q "$directory"
  git -C "$directory" fetch -q --depth 1 --no-tags "https://github.com/$repository.git" "$revision"
  git -C "$directory" checkout -q --detach FETCH_HEAD
  test "$(git -C "$directory" rev-parse HEAD)" = "$revision"
}

checkout Dinext-pro/dinext_platform de9b663eb808e8ffbe7d38a0a3233a45745831a6 apps/frappe
checkout Dinext-pro/dinext_erp 548e80297397ba5d3ca4fb111a923fe784a37f4e apps/erpnext
checkout Dinext-pro/dinext-common 8b84bebbee3209f2612d0f8456a24db2b12d2cc2 apps/dinext_common
checkout Dinext-pro/dinext-raven f440649d7ce7d0efa241ef3de89bd6eed46b38f7 apps/dinext_raven

revision=$(git -C "$source_dir" rev-parse HEAD)
baseline=$(python -c 'import json, sys; print(json.load(open(sys.argv[1]))["prior_dinext_commit"])' "$source_dir/.github/dinext-upstream.json")
[[ "$baseline" =~ ^[0-9a-f]{40}$ ]]
checkout "$GITHUB_REPOSITORY" "$baseline" "baseline/$app"
git -C "$source_dir" worktree add --quiet --detach "$bench_dir/apps/$app" "$revision"
printf '%s\n' frappe erpnext "$app" dinext_common dinext_raven > sites/apps.txt
cat > sites/common_site_config.json <<'JSON'
{"db_host":"127.0.0.1","db_port":3306,"redis_cache":"redis://127.0.0.1:6379/0","redis_queue":"redis://127.0.0.1:6379/1","redis_socketio":"redis://127.0.0.1:6379/2","socketio_port":9000,"developer_mode":1,"allow_tests":true,"server_script_enabled":1,"disable_scheduler":1,"pause_scheduler":1}
JSON

python -m venv env
export PATH="$bench_dir/env/bin:$PATH"
python -m pip install -q -e apps/frappe -e apps/erpnext -e "baseline/$app" -e apps/dinext_common -e apps/dinext_raven
frappe_cli() {
  (cd "$bench_dir/sites" && python -m frappe.utils.bench_helper frappe "$@")
}
migration_fixture() (
  cd "$bench_dir/sites"
  python - "$site" "$1" <<'PYTHON'
import sys

import frappe

frappe.init(sys.argv[1])
frappe.connect()
frappe.set_user("Administrator")
title = "Dinext migration fixture"
if sys.argv[2] == "seed":
    frappe.get_doc({"doctype": "Warehouse Type", "name": "Transit"}).insert()
    frappe.get_doc({
        "doctype": "Raven Workspace", "workspace_name": title, "type": "Private",
    }).insert()
    frappe.db.commit()
else:
    assert frappe.db.exists("Raven Workspace", {"workspace_name": title})
    assert frappe.db.get_single_value("Raven Settings", "setup_completed")
frappe.destroy()
PYTHON
)
admin_password=$(python -c 'import secrets; print(secrets.token_urlsafe(24))')
echo "::add-mask::$admin_password"
frappe_cli new-site "$site" --db-root-password ci --admin-password "$admin_password" --mariadb-user-host-login-scope='%'
frappe_cli --site "$site" install-app erpnext "$app"
migration_fixture seed

python -m pip install -q --no-deps -e "apps/$app"
python -m pip check
frappe_cli --site "$site" migrate 2>&1 | tee "$reports/migration.log"
migration_fixture verify
frappe_cli --site "$site" install-app dinext_common dinext_raven

yarn --cwd apps/frappe install --frozen-lockfile --non-interactive
yarn --cwd apps/erpnext install --frozen-lockfile --non-interactive
yarn --cwd "apps/$app" install --frozen-lockfile --non-interactive --ignore-scripts
yarn --cwd apps/dinext_common install --frozen-lockfile --non-interactive
frappe_cli --site "$site" build --production --force 2>&1 | tee "$reports/build.log"
frappe_cli --site "$site" clear-cache

printf 'Tested %s at `%s` after migration from `%s`.\n' "$app" "$revision" "$baseline" | tee "$reports/revision.txt" >> "$GITHUB_STEP_SUMMARY"

if [[ "$phase" == compatibility ]]; then
  python -m pip install -q unittest-xml-reporting==3.2.0
  yarn --cwd apps/raven/apps/web test
  frappe_cli --site "$site" run-tests --app raven --module raven.tests.test_permissions --junit-xml-output "$reports/test_permissions.xml"
  frappe_cli --site "$site" run-tests --app dinext_raven --module dinext_raven.tests.test_document_channels --junit-xml-output "$reports/test_document_channels.xml"
  frappe_cli --site "$site" run-tests --app dinext_raven --module dinext_raven.tests.test_translations --junit-xml-output "$reports/test_translations.xml"
else
  (cd sites && python - "$site" <<'PYTHON'
import sys

import frappe
from frappe.desk.page.setup_wizard.setup_wizard import enable_setup_wizard_complete

frappe.init(sys.argv[1])
frappe.connect()
for app_name in ("frappe", "erpnext"):
    enable_setup_wizard_complete(app_name)
frappe.db.set_single_value("System Settings", "setup_complete", 1)

frappe.db.commit()
frappe.clear_cache()
frappe.destroy()
PYTHON
  )
  (cd sites && DEV_SERVER=1 python -m frappe.utils.bench_helper frappe --site "$site" serve --port 8000 --noreload) > "$reports/web.log" 2>&1 & web_pid=$!
  trap 'kill "$web_pid" 2>/dev/null || true; tail -n 30 "$reports/web.log"' EXIT
  curl --fail --silent --show-error --retry 30 --retry-connrefused --retry-delay 2 "http://127.0.0.1:8000/api/method/ping"
  export CYPRESS_BASE_URL="http://127.0.0.1:8000"
  node apps/frappe/socketio.js > "$reports/socketio.log" 2>&1 & socket_pid=$!
  trap 'kill "$web_pid" "$socket_pid" 2>/dev/null || true; tail -n 30 "$reports/web.log" "$reports/socketio.log"' EXIT
  npx --yes --package=cypress@13.17.0 cypress run --project "apps/$app" --reporter junit --reporter-options "mochaFile=$reports/$app-browser-[hash].xml" --env "adminPassword=$admin_password"
fi
