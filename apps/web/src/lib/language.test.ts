import { afterEach, describe, expect, it, vi } from "vitest"
import dayjs from "dayjs"
import { initializeLanguage } from "./language"
import _ from "./translate"

afterEach(() => {
    vi.unstubAllGlobals()
    dayjs.locale("en")
})

describe("initializeLanguage", () => {
    it("loads Russian boot messages and calendar names on an online load", async () => {
        const frappe = { boot: { lang: "ru", __messages: { Send: "Отправить" } } }
        const documentElement = { lang: "en" }
        vi.stubGlobal("window", { frappe })
        vi.stubGlobal("document", { documentElement })
        await initializeLanguage(frappe.boot)
        expect(_("Send")).toBe("Отправить")
        expect(documentElement.lang).toBe("ru")
        expect(dayjs("2026-10-02").format("dddd, D MMMM")).toBe("пятница, 2 октября")
    })

    it("uses English fallback without a language or message dictionary", async () => {
        vi.stubGlobal("window", { frappe: { boot: {} } })
        const documentElement = { lang: "ru" }
        vi.stubGlobal("document", { documentElement })
        dayjs.locale("ru")
        await initializeLanguage({})
        expect(_("Send")).toBe("Send")
        expect(documentElement.lang).toBe("en")
        expect(dayjs.locale()).toBe("en")
    })

})
