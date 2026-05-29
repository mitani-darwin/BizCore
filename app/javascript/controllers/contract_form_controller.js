import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["customerField", "supplierField"]

  onTypeChange(event) {
    const type = event.target.value
    this.customerFieldTarget.classList.toggle("hidden", type !== "customer")
    this.supplierFieldTarget.classList.toggle("hidden", type !== "supplier")
  }
}
