import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate", "daysCount"]

  connect() {
    this.calculate()
  }

  calculate() {
    const start = this.startDateTarget.value
    const end = this.endDateTarget.value
    if (!start || !end) return

    const startDate = new Date(start)
    const endDate = new Date(end)
    if (endDate < startDate) return

    const days = Math.round((endDate - startDate) / (1000 * 60 * 60 * 24)) + 1
    this.daysCountTarget.value = days
  }
}
