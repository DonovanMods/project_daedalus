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
        icarus: {
          100: "#fcefd2",
          200: "#f9dea4",
          300: "#f7ce77",
          400: "#f4bd49",
          500: "#f1ad1c",
          600: "#c18a16",
          700: "#916811",
          800: "#60450b",
          900: "#302306"
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
