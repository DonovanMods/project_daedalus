import { Controller } from "@hotwired/stimulus"

// Tracks mod page views and download counts in localStorage
// This is client-side only — no server writes required
export default class extends Controller {
  static values = { modId: String }

  connect() {
    if (!this.modIdValue) return
    this.recordView()
    this.renderStats()
  }

  recordView() {
    const views = this.getViews()
    views[this.modIdValue] = (views[this.modIdValue] || 0) + 1
    localStorage.setItem("mod_views", JSON.stringify(views))
  }

  recordDownload(event) {
    const modId = event.params?.modId || this.modIdValue
    if (!modId) return

    const downloads = this.getDownloads()
    downloads[modId] = (downloads[modId] || 0) + 1
    localStorage.setItem("mod_downloads", JSON.stringify(downloads))
    this.renderStats()
  }

  getViews() {
    try {
      return JSON.parse(localStorage.getItem("mod_views") || "{}")
    } catch {
      return {}
    }
  }

  getDownloads() {
    try {
      return JSON.parse(localStorage.getItem("mod_downloads") || "{}")
    } catch {
      return {}
    }
  }

  renderStats() {
    const viewCount = this.getViews()[this.modIdValue] || 0
    const downloadCount = this.getDownloads()[this.modIdValue] || 0

    const viewEl = document.getElementById("analytics-view-count")
    const dlEl = document.getElementById("analytics-download-count")

    if (viewEl) viewEl.textContent = viewCount
    if (dlEl) dlEl.textContent = downloadCount
  }
}
