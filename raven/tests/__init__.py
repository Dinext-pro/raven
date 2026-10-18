global_test_dependencies = ["User", "Raven User"]

# Keep the same server tests runnable on both supported Frappe release lines.
try:
	from frappe.tests import IntegrationTestCase as RavenTestCase
except ImportError:
	from frappe.tests.utils import FrappeTestCase

	class RavenTestCase(FrappeTestCase):
		@classmethod
		def setUpClass(cls):
			from frappe.test_runner import make_test_records

			for doctype in global_test_dependencies:
				make_test_records(doctype, commit=True)
			from raven.api.search import RavenSearch

			search = RavenSearch()
			if not search.index_exists():
				search.build_index()
			super().setUpClass()
