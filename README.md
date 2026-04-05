# Project Daedalus

![Auditing Workflow](https://github.com/donovanmods/project_daedalus/actions/workflows/rubyonrails.yml/badge.svg?branch=main)

Website for the [Daedalus Project](https://projectdaedalus.app); Icarus Modding Tools

Built with Rails 7.2, Ruby 3.4, Tailwind CSS, and Google Cloud Firestore.

- Mod Listings (`.pak`, `.zip`, `.exmodz`, `.exmod` formats)
- Modding Tool Links
- i18n-ready (English by default, infrastructure for additional languages)
- Analytics dashboard for mod authors
- GitHub repository stats integration

## Development

```bash
bin/setup    # Initial setup
bin/dev      # Start dev server with Tailwind watch
bin/rspec    # Run tests
bin/audit    # Run security audits (bundle-audit + brakeman + rubocop)
```

## License

Website Code is Copyright 2023-2026 Donovan Young and released under MIT licensing
