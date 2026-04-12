import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "toggleAllLabel"]
  static values = {
    storageKey: { type: String, default: "admin-sidebar-sections" }
  }

  connect() {
    this.state = this.loadState()
    this.sectionTargets.forEach((section) => {
      const sectionId = section.dataset.sidebarSectionId
      const persistedState = this.state[sectionId]
      const defaultOpen = section.dataset.sidebarDefaultOpen !== "false"
      const activeSection = section.dataset.sidebarActive === "true"
      const open = activeSection ? true : (persistedState == null ? defaultOpen : persistedState)

      this.applySectionState(section, open)
    })
    this.syncToggleAllLabel()
  }

  toggleSection(event) {
    const section = event.currentTarget.closest("[data-sidebar-section-id]")
    if (!section) return

    this.applySectionState(section, !this.sectionOpen(section))
    this.syncToggleAllLabel()
    this.persistState()
  }

  toggleAll() {
    const shouldOpen = !this.sectionTargets.every((section) => this.sectionOpen(section))

    this.sectionTargets.forEach((section) => {
      this.applySectionState(section, shouldOpen)
    })

    this.syncToggleAllLabel()
    this.persistState()
  }

  sectionOpen(section) {
    return section.dataset.sidebarOpen === "true"
  }

  applySectionState(section, open) {
    section.dataset.sidebarOpen = open ? "true" : "false"

    const button = section.querySelector("[data-sidebar-role='button']")
    const panel = section.querySelector("[data-sidebar-role='panel']")
    const icon = section.querySelector("[data-sidebar-role='icon']")

    if (button) {
      button.setAttribute("aria-expanded", open ? "true" : "false")
    }

    if (panel) {
      panel.classList.toggle("hidden", !open)
    }

    if (icon) {
      icon.classList.toggle("rotate-90", open)
    }
  }

  syncToggleAllLabel() {
    if (!this.hasToggleAllLabelTarget) return

    const allOpen = this.sectionTargets.every((section) => this.sectionOpen(section))
    this.toggleAllLabelTarget.textContent = allOpen ? "すべて折りたたむ" : "すべて展開"
  }

  persistState() {
    const nextState = this.sectionTargets.reduce((result, section) => {
      result[section.dataset.sidebarSectionId] = this.sectionOpen(section)
      return result
    }, {})

    this.state = nextState

    try {
      window.localStorage.setItem(this.storageKeyValue, JSON.stringify(nextState))
    } catch (_error) {
      // localStorage が使えない環境では保持なしで継続する
    }
  }

  loadState() {
    try {
      const raw = window.localStorage.getItem(this.storageKeyValue)
      return raw ? JSON.parse(raw) : {}
    } catch (_error) {
      return {}
    }
  }
}
