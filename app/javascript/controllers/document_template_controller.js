import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "companyHeaderSection",
    "companyHeaderEnabledInput",
    "col",
    "columnLabel",
  ]

  static values = {
    columnWidths: Array,
  }

  connect() {
    this._resizing = false
    this._boundMouseMove = this._doResize.bind(this)
    this._boundMouseUp = this._stopResize.bind(this)
    this._updateColumnDisplay()
    this._initRowVisibility()
  }

  disconnect() {
    document.removeEventListener("mousemove", this._boundMouseMove)
    document.removeEventListener("mouseup", this._boundMouseUp)
  }

  // ── Company Header ──────────────────────────────────────────

  toggleCompanyHeader(event) {
    const enabled = event.target.checked
    this.companyHeaderSectionTarget.classList.toggle("hidden", !enabled)
    this.companyHeaderEnabledInputTarget.value = enabled ? "1" : "0"
  }

  syncCompanyField(event) {
    const div = event.currentTarget
    const field = div.dataset.field
    const value = div.textContent.trim()
    const input = this.element.querySelector(
      `[name="document_template[settings][${field}]"]`
    )
    if (input) input.value = value
  }

  // ── Row Visibility ──────────────────────────────────────────

  _initRowVisibility() {
    this.element.querySelectorAll("[data-info-row]").forEach(row => {
      const visible = row.dataset.visible !== "false"
      this._applyRowVisual(row, visible)
    })
  }

  toggleRow(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const key = btn.dataset.rowKey
    const row = this.element.querySelector(`[data-info-row][data-row-key="${key}"]`)
    if (!row) return

    const newVisible = row.dataset.visible === "false"
    row.dataset.visible = String(newVisible)
    this._applyRowVisual(row, newVisible)

    const input = this.element.querySelector(
      `[name="document_template[settings][row_visibility][${key}]"]`
    )
    if (input) input.value = newVisible ? "1" : "0"
  }

  _applyRowVisual(row, visible) {
    row.style.opacity = visible ? "1" : "0.3"
    const eyeEl = row.querySelector("[data-icon='eye']")
    const eyeOffEl = row.querySelector("[data-icon='eye-off']")
    if (eyeEl) eyeEl.classList.toggle("hidden", !visible)
    if (eyeOffEl) eyeOffEl.classList.toggle("hidden", visible)
  }

  // ── Column Label Double-click Edit ──────────────────────────

  startEditLabel(event) {
    const th = event.currentTarget
    const colIndex = parseInt(th.dataset.colIndex)
    const labelEl = this.columnLabelTargets.find(
      el => parseInt(el.dataset.colIndex) === colIndex && el.tagName !== "INPUT"
    )
    if (!labelEl) return

    const currentValue = labelEl.textContent.trim()
    const defaultLabel = th.dataset.defaultLabel || ""

    const input = document.createElement("input")
    input.type = "text"
    input.value = currentValue
    input.placeholder = defaultLabel
    input.className =
      "w-full bg-transparent text-xs font-semibold text-slate-700 focus:outline-none focus:ring-1 focus:ring-sky-400 rounded border-0 px-0"
    input.dataset.documentTemplateTarget = "columnLabel"
    input.dataset.colIndex = String(colIndex)
    labelEl.replaceWith(input)
    input.focus()
    input.select()

    const finish = () => {
      const newValue = input.value.trim()
      const span = document.createElement("span")
      span.textContent = newValue || defaultLabel
      span.dataset.documentTemplateTarget = "columnLabel"
      span.dataset.colIndex = String(colIndex)
      input.replaceWith(span)

      const colKey = th.dataset.colKey
      const hiddenInput = this.element.querySelector(
        `[name="document_template[settings][item_column_labels][${colKey}]"]`
      )
      if (hiddenInput) hiddenInput.value = newValue
    }

    input.addEventListener("blur", finish, { once: true })
    input.addEventListener("keydown", e => {
      if (e.key === "Enter") { e.preventDefault(); input.blur() }
      if (e.key === "Escape") { input.value = currentValue; input.blur() }
    })
  }

  // ── Column Resize ───────────────────────────────────────────

  startResize(event) {
    event.preventDefault()
    this._resizing = true
    this._resizeColIndex = parseInt(event.currentTarget.dataset.colIndex)
    this._resizeStartX = event.clientX
    this._resizeStartWidths = [...this.columnWidthsValue]

    document.addEventListener("mousemove", this._boundMouseMove)
    document.addEventListener("mouseup", this._boundMouseUp)
    document.body.style.cursor = "col-resize"
    document.body.style.userSelect = "none"
  }

  _doResize(event) {
    if (!this._resizing) return

    const table = this.element.querySelector("table[data-resize-table]")
    if (!table) return

    const dx = event.clientX - this._resizeStartX
    const tableWidth = table.offsetWidth
    const totalUnits = this._resizeStartWidths.reduce((a, b) => a + b, 0)
    if (tableWidth === 0 || totalUnits === 0) return

    const pixelsPerUnit = tableWidth / totalUnits
    const deltaUnits = Math.round(dx / pixelsPerUnit)
    const i = this._resizeColIndex
    const j = i + 1
    const newI = this._resizeStartWidths[i] + deltaUnits
    const newJ = this._resizeStartWidths[j] - deltaUnits

    if (newI >= 4 && newJ >= 4) {
      const newWidths = [...this._resizeStartWidths]
      newWidths[i] = newI
      newWidths[j] = newJ
      this.columnWidthsValue = newWidths
      this._updateColumnDisplay()
    }
  }

  _stopResize() {
    if (!this._resizing) return
    this._resizing = false
    document.removeEventListener("mousemove", this._boundMouseMove)
    document.removeEventListener("mouseup", this._boundMouseUp)
    document.body.style.cursor = ""
    document.body.style.userSelect = ""
    this._syncColumnWidthInputs()
  }

  _updateColumnDisplay() {
    const widths = this.columnWidthsValue
    if (!widths.length) return
    const total = widths.reduce((a, b) => a + b, 0)
    if (total === 0) return
    this.colTargets.forEach(col => {
      const i = parseInt(col.dataset.colIndex)
      col.style.width = `${(widths[i] / total * 100).toFixed(2)}%`
    })
  }

  _syncColumnWidthInputs() {
    this.columnWidthsValue.forEach((width, i) => {
      const input = this.element.querySelector(
        `[name="document_template[settings][column_widths][${i}]"]`
      )
      if (input) input.value = width
    })
  }
}
