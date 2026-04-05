# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Additional Directives

This is a Rails project, read ~/.claude/RUBY.md and ~/.claude/RAILS.md for additional instructions

## Project Overview

Project Daedalus is a Rails 7.2 application that serves as a website for the Icarus Modding Tools community, featuring mod and tool listings. The application uses Ruby 3.4.9 and Google Cloud Firestore as its data backend.

## Architecture

### Data Model

The application uses **Firestore as its database** instead of Active Record. Two main models (`Mod` and `Tool`) include the `Firestorable` concern to connect to Google Cloud Firestore:

- **Mod**: Represents game modifications with support for multiple file formats (`.pak`, `.zip`, `.exmodz`, `.exmod`)
- **Tool**: Represents modding tools and utilities

Both models use `ActiveModel::Model` rather than `ActiveRecord::Base` and include key concerns:

- `Firestorable`: Provides Firestore connection using credentials from Rails encrypted credentials
- `Convertable`: Handles URL transformations (e.g., converting GitHub URLs to raw content URLs)
- `Displayable`: Formatting helpers for display strings (updated_string, version_string, author_slug, readme fetching)
- `GithubStats` (Mod only): Non-blocking async GitHub API stats with cache-first pattern and sentinel-based dogpile prevention

### Controllers

Standard Rails controllers handle routing:
- `ModsController`: Lists and displays mods, supports filtering by author, prev/next navigation, analytics
- `ToolsController`: Lists tools by author
- `HomeController`: Static home page
- `InfoController`: Static info page
- `LocalesController`: Handles locale switching via cookie persistence

### i18n

The application uses Rails i18n with all user-visible strings in `config/locales/en.yml`. The locale detection chain is: cookie → Accept-Language header → default (en). To add a new language, drop in a locale YAML file and add the symbol to `config.i18n.available_locales` in `config/application.rb`.

### Frontend

- **Tailwind CSS** for styling (watch with `bin/rails tailwindcss:watch`)
- **Stimulus** and **Turbo** for interactivity
- **Importmap** for JavaScript module management

### Deployment

Uses **Kamal** for Docker-based deployment to a single web server (10.30.11.2). Configuration in `config/deploy.yml` includes:
- Docker image: `dyoung522/project-daedalus`
- Google Cloud integration (Firestore, Storage)
- Environment variables for production database and cloud services
- Aliases for `shell` and `console` access

## Common Commands

### Setup

```bash
bin/setup              # Initial setup: installs dependencies, prepares DB, clears logs/tmp
```

### Development

```bash
bin/dev                # Start development server with Tailwind CSS watch (uses Foreman and Procfile.dev)
bin/rails server       # Start Rails server only (port 3000)
bin/rails console      # Open Rails console
```

### Testing

```bash
bin/rspec                           # Run all specs
bin/rspec spec/models/mod_spec.rb   # Run specific spec file
bundle exec guard                   # Run Guard for automatic test runs on file changes
```

The project uses RSpec with:
- FactoryBot for test data
- Faker for generating realistic fake data
- Request specs in `spec/requests/`
- Model specs in `spec/models/`
- Shared concern specs in `spec/models/concerns/`

### Linting & Code Quality

```bash
bin/audit                           # Run all security audits (bundle-audit + brakeman + standardrb)
bundle exec standardrb              # Run Standard Ruby linter (auto-fix with --fix)
bundle exec standardrb --parallel   # Faster linting with parallel processing
bundle exec rubocop                 # Run RuboCop (available in development)
bundle exec brakeman                # Security vulnerability scanner
bundle exec bundle-audit            # Check gems for known vulnerabilities
bundle exec erb_lint                # Lint ERB templates
```

Standard Ruby configuration is in `.standard.yml` with extensions in `.standard_rubocop_extensions.yml`.

### Deployment

```bash
kamal deploy           # Deploy application using Kamal
kamal app logs         # View application logs
kamal shell            # Open bash shell in container (alias configured)
kamal console          # Open Rails console in production (alias configured)
```

## Testing Guidelines

1. Always start with a test for functional code changes
2. Use FactoryBot factories (in `spec/factories/`) for creating test data
3. Request specs should test HTTP responses and routing
4. Model specs should test business logic and concern behavior
5. Since models don't use ActiveRecord, focus on testing the Firestore integration and data transformation methods
6. Firestore is unavailable in CI — request specs that hit `root_path` (routes to `mods#index`) will fail. Use `/home` for locale/routing tests instead
7. Helper specs in `spec/helpers/` for view helper methods (e.g., `ModHelper`, `AnalyticsHelper`)
8. View specs in `spec/views/` for template rendering

## Key Dependencies

- **google-cloud-firestore**: Database backend
- **google-cloud-storage**: File storage
- **redcarpet**: Markdown rendering for READMEs
- **dotenv-rails**: Environment variable management
- **standard**: Ruby style guide and linter
