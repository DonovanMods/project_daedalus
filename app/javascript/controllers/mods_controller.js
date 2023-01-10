import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  goToMods() {
    window.location.href = "/mods"
  }

  goToMod({ params }) {
    window.location.href = `/mods/${params.id}`
  }

  download({ params }) {
    const [url, fileName] = [params.url, params.fileName];
    const anchor = document.createElement("a");

    anchor.href = url;
    anchor.download = fileName;

    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
  }
}
