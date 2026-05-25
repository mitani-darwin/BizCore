import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate", "daysCount", "halfDayType", "endDateRow"]

  connect() {
    this.syncHalfDay()
  }

  calculate() {
    if (!this.isFullDay()) return

    const start = this.startDateTarget.value
    const end = this.endDateTarget.value
    if (!start || !end) return

    const startDate = new Date(start)
    const endDate = new Date(end)
    if (endDate < startDate) return

    const days = Math.round((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1
    this.daysCountTarget.value = days
  }

  syncHalfDay() {
    if (this.isFullDay()) {
      if (this.hasEndDateRowTarget) this.endDateRowTarget.style.display = ""
      this.daysCountTarget.readOnly = false
      this.daysCountTarget.classList.remove("bg-slate-100", "text-slate-500")
      this.calculate()
    } else {
      if (this.hasEndDateRowTarget) this.endDateRowTarget.style.display = "none"
      if (this.startDateTarget.value) {
        this.endDateTarget.value = this.startDateTarget.value
      }
      this.daysCountTarget.value = "0.5"
      this.daysCountTarget.readOnly = true
      this.daysCountTarget.classList.add("bg-slate-100", "text-slate-500")
    }
  }

  onStartDateChange() {
    if (!this.isFullDay() && this.startDateTarget.value) {
      this.endDateTarget.value = this.startDateTarget.value
    }
    this.calculate()
  }

  isFullDay() {
    return !this.hasHalfDayTypeTarget || this.halfDayTypeTarget.value === "none"
  }
}
