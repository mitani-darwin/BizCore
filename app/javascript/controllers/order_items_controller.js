import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows", "template", "row"]
  static values = { index: Number }

  addRow() {
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", String(this.indexValue))
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.indexValue += 1
  }

  removeRow(event) {
    event.preventDefault()

    const row = event.currentTarget.closest("[data-order-items-target='row']")
    if (!row) return

    const destroyField = row.querySelector("input[name*='[_destroy]']")
    const idField = row.querySelector("input[name*='[id]']")

    if (destroyField) {
      destroyField.value = "1"
    }

    if (idField && idField.value) {
      row.classList.add("hidden")
    } else {
      row.remove()
    }

    if (this.visibleRowsCount === 0) {
      this.addRow()
    }
  }

  get visibleRowsCount() {
    return this.rowTargets.filter((row) => !row.classList.contains("hidden")).length
  }
}
