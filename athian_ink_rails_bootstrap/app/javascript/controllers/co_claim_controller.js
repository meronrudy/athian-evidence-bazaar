import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "share",
    "progress",
    "status",
    "remaining",
    "saveButton",
    "claimedQuantity",
    "remainingQuantity"
  ]

  static values = {
    cap: Number,
    verifiedTotal: Number
  }

  connect() {
    this.recalculate()
  }

  recalculate() {
    const total = this.shareTargets.reduce((sum, input) => sum + this.number(input.value), 0)
    const remaining = Math.max(this.capValue - total, 0)
    const overCap = total > this.capValue
    const exactCap = Math.abs(total - this.capValue) < 0.001
    const width = Math.min(total, 100)
    const claimedQuantity = this.verifiedTotalValue * total / 100
    const remainingQuantity = Math.max(this.verifiedTotalValue - claimedQuantity, 0)

    this.progressTarget.style.width = `${width}%`
    this.progressTarget.textContent = `${total.toFixed(2)}%`
    this.progressTarget.classList.toggle("bg-danger", overCap)
    this.progressTarget.classList.toggle("bg-success", !overCap)
    this.statusTarget.textContent = overCap
      ? `Aggregate claim exceeds cap by ${(total - this.capValue).toFixed(2)}%`
      : `Aggregate claim: ${total.toFixed(2)}%`
    this.remainingTarget.textContent = overCap
      ? "No allocation can be saved above the verified aggregate cap."
      : `${remaining.toFixed(2)}% remaining`
    this.claimedQuantityTarget.textContent = claimedQuantity.toFixed(3)
    this.remainingQuantityTarget.textContent = remainingQuantity.toFixed(3)
    this.saveButtonTarget.disabled = !exactCap
  }

  number(value) {
    const parsed = Number.parseFloat(value)
    return Number.isFinite(parsed) ? parsed : 0
  }
}
