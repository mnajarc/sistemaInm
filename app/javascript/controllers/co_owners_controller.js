import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    this.nextIndex = this.listTarget.querySelectorAll(".co-owner-form").length
  }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.nextIndex)
    this.listTarget.insertAdjacentHTML("beforeend", content)
    this.nextIndex++
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(".co-owner-form")
    if (wrapper) {
      wrapper.querySelector("input[name*='_destroy']").value = 1
      wrapper.style.display = "none"
    }
  }
}
