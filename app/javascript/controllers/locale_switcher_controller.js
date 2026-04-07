import { Controller } from "@hotwired/stimulus"

// Submits the locale form when the select value changes
// CSP-compliant replacement for inline onchange handler
export default class extends Controller {
  submit() {
    this.element.querySelector("form")?.submit()
  }
}
