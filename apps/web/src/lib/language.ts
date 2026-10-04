import dayjs from "dayjs"
import "dayjs/locale/ru"

/** Initialize the online and offline app from the same boot language. */
export function initializeLanguage() {
    const frappe = window.frappe
    if (!frappe?.boot) return
    const language = frappe.boot.lang || "en"
    frappe._messages = frappe.boot.__messages || {}
    document.documentElement.lang = language
    dayjs.locale(language === "ru" ? "ru" : "en")
}
