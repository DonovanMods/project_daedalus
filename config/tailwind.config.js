const defaultTheme = require("tailwindcss/defaultTheme")

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans]
      },
      backgroundImage: {
        "topo-light": "url('/bg-topography-light.svg')",
        "topo-dark": "url('/bg-topography-dark.svg')"
      },
      colors: {
        "icarus": {
          100: "#f9f2d4",
          200: "#f3e5a8",
          300: "#ecd97d",
          400: "#e6cc51",
          500: "#e0bf26",
          600: "#b3991e",
          700: "#867317",
          800: "#5a4c0f",
          900: "#2d2608"
        }
      }
    }
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
  ]
}
