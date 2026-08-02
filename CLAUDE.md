# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Additional Directives

This is a Rails project, read ~/.claude/RUBY.md and ~/.claude/RAILS.md for additional instructions

## Project Overview

Project Daedalus is a Rails 8.1 application that serves as a website for the Icarus Modding Tools community, featuring mod and tool listings. The application uses Ruby 4.0.6 and Google Cloud Firestore as its data backend.

## Architecture

### Data Model

The application uses **Firestore as its database** instead of Active Record. Two main models (`Mod` and `Tool`) include the `Firestorable` concern to connect to Google Cloud Firestore:

- **Mod**: Represents game modifications with support for multiple file formats (`.pak`, `.zip`, `.exmodz`)
- **Tool**: Represents modding tools and utilities

Both models use `ActiveModel::Model` rather than `ActiveRecord::Base` and include two key concerns:

- `Firestorable`: Provides Firestore connection using credentials from Rails encrypted credentials
- `Convertable`: Handles URL transformations (e.g., converting GitHub URLs to raw content URLs)

### Controllers

Standard Rails controllers handle routing:
- `ModsController`: Lists and displays mods, supports filtering by author
- `ToolsController`: Lists tools by author (detail view commented out)
- `HomeController`: Static home page
- `InfoController`: Static info page

### Frontend

- **Tailwind CSS v4** for styling, configured CSS-first in `app/assets/tailwind/application.css` (no `tailwind.config.js`); watch with `bin/rails tailwindcss:watch`
- **Stimulus** and **Turbo** for interactivity
- **Importmap** for JavaScript module management

### Background Jobs & Caching (Solid Stack)

Uses Rails 8's Solid Cache/Queue/Cable, each backed by its own SQLite database under `storage/` (see `config/database.yml`: `production_cache.sqlite3`, `production_queue.sqlite3`, `production_cable.sqlite3`, alongside the primary `production.sqlite3`). In the single-server production deployment, the `SOLID_QUEUE_IN_PUMA` env var (set in `config/deploy.yml`) makes Puma run the Solid Queue supervisor in-process (see `config/puma.rb`).

### Deployment

Uses **Kamal** for Docker-based deployment to a single web server (10.30.11.2). Configuration in `config/deploy.yml` includes:
- Docker image: `dyoung522/project-daedalus`
- Google Cloud integration (Firestore, Storage)
- Environment variables for production database and cloud services, including `SOLID_QUEUE_IN_PUMA`
- Persistent volumes for `/rails/tmp` and `/rails/storage` (the latter holds the primary and Solid Cache/Queue/Cable SQLite databases, which must survive deploys)
- Aliases for `shell` and `console` access

`docker-entrypoint.sh` runs `bin/rails db:prepare` before `bin/rails server` invocations, which creates/migrates the primary database and the Solid Cache/Queue/Cable databases (multi-database aware).

## Common Commands

### Setup

```bash
bin/setup                # Installs dependencies, prepares DB, clears logs/tmp, then execs bin/dev to start the server
bin/setup --skip-server  # Same as above, but does not start the server afterward
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
bin/audit                           # Run all checks: bundle-audit + brakeman + rubocop --parallel
bundle exec rubocop                 # Run RuboCop
bundle exec rubocop --parallel      # Faster linting with parallel processing
bundle exec brakeman                # Security vulnerability scanner
bundle exec bundle-audit            # Check gems for known vulnerabilities
```

RuboCop configuration is in `.rubocop.yml`.

### Deployment

```bash
kamal deploy           # Deploy application using Kamal
kamal app logs         # View application logs
kamal shell            # Open bash shell in container (alias configured)
kamal console          # Open Rails console in production (alias configured)
```

## Testing Guidelines

1. Use FactoryBot factories (in `spec/factories/`) for creating test data
2. Request specs should test HTTP responses and routing
3. Model specs should test business logic and concern behavior
4. Since models don't use ActiveRecord, focus on testing the Firestore integration and data transformation methods

## Key Dependencies

- **google-cloud-firestore**: Database backend
- **google-cloud-storage**: File storage
- **redcarpet**: Markdown rendering for READMEs
- **dotenv-rails**: Environment variable management
- **rubocop** (+ rubocop-rails, rubocop-performance, rubocop-rspec): Ruby style guide and linter
