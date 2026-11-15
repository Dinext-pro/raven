import dayjs from "dayjs"
import "dayjs/locale/ru"
import { loadTranslations } from "./translations"

/** Initialize the online and offline app from the same boot language. */
export async function initializeLanguage(boot: Parameters<typeof loadTranslations>[0]) {
    const language = boot.lang || "en"
    document.documentElement.lang = language
    dayjs.locale(language === "ru" ? "ru" : "en")
    await loadTranslations(boot)
}
