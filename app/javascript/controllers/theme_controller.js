import { Controller } from "@hotwired/stimulus"

// Manages dark/light theme toggle with localStorage persistence.
// Falls back to OS preference when no saved preference exists.
export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.updateIcon()
  }

  toggle() {
    const html = document.documentElement
    if (html.classList.contains("dark")) {
      html.classList.remove("dark")
      localStorage.setItem("theme", "light")
    } else {
      html.classList.add("dark")
      localStorage.setItem("theme", "dark")
    }
    this.updateIcon()
  }

  updateIcon() {
    if (!this.hasIconTarget) return
    const isDark = document.documentElement.classList.contains("dark")
    this.iconTarget.innerHTML = isDark ? "\uD83C\uDF19" : "\u2600\uFE0F"
  }
}
