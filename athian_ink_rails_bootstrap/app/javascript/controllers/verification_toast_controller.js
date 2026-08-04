import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

export default class extends Controller {
  static targets = ["toast"]
  static values = { status: String }

  connect() {
    const toast = Toast.getOrCreateInstance(this.toastTarget, { delay: 7000 })
    toast.show()
  }
}
