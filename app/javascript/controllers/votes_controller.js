import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "count", "icon"]
  static values = { url: String, modId: String }

  connect() {
    this.fingerprint = this.generateFingerprint()
    this.voted = this.hasVoted()
    this.updateUI()
  }

  async toggle(event) {
    event.preventDefault()
    event.stopImmediatePropagation()

    if (this.submitting) return
    this.submitting = true

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ fingerprint: this.fingerprint })
      })

      if (response.ok) {
        const data = await response.json()
        this.voted = data.voted
        this.persistVote(data.voted)
        this.countTarget.textContent = data.count
        this.updateUI()
      } else if (response.status === 429) {
        this.buttonTarget.classList.add("animate-shake")
        setTimeout(() => this.buttonTarget.classList.remove("animate-shake"), 500)
      }
    } catch (error) {
      console.error("Vote failed:", error)
    } finally {
      this.submitting = false
    }
  }

  updateUI() {
    if (this.voted) {
      this.iconTarget.innerHTML = this.filledHeart()
      this.buttonTarget.classList.add("text-red-500")
      this.buttonTarget.classList.remove("text-slate-400")
    } else {
      this.iconTarget.innerHTML = this.outlineHeart()
      this.buttonTarget.classList.remove("text-red-500")
      this.buttonTarget.classList.add("text-slate-400")
    }
  }

  // Lightweight browser fingerprint — not tracking, just dedup
  generateFingerprint() {
    const components = [
      screen.width,
      screen.height,
      screen.colorDepth,
      new Date().getTimezoneOffset(),
      navigator.language,
      navigator.platform,
      navigator.hardwareConcurrency || "",
      navigator.userAgent
    ]

    const raw = components.join("|")
    return this.simpleHash(raw)
  }

  // Simple string hash (djb2 algorithm)
  simpleHash(str) {
    let hash = 5381
    for (let i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.charCodeAt(i)
      hash = hash & hash // Convert to 32bit integer
    }
    return Math.abs(hash).toString(36)
  }

  hasVoted() {
    try {
      const votes = JSON.parse(localStorage.getItem("mod_votes") || "{}")
      return votes[this.modIdValue] === this.fingerprint
    } catch {
      return false
    }
  }

  persistVote(voted) {
    try {
      const votes = JSON.parse(localStorage.getItem("mod_votes") || "{}")
      if (voted) {
        votes[this.modIdValue] = this.fingerprint
      } else {
        delete votes[this.modIdValue]
      }
      localStorage.setItem("mod_votes", JSON.stringify(votes))
    } catch {
      // localStorage unavailable, that's fine — server-side dedup still works
    }
  }

  filledHeart() {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5">
      <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z"/>
    </svg>`
  }

  outlineHeart() {
    return `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
      <path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"/>
    </svg>`
  }
}
