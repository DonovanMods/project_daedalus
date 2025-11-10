# Project Daedalus - AI Copilot Instructions

## Project Overview

Project Daedalus is a Rails 7.0 web application that catalogs modding tools and mods for the Icarus game. The site displays listings pulled from a Google Cloud Firestore database, with no traditional ActiveRecord models—instead using Plain Old Ruby Objects (POROs) that fetch data from Firestore.

**Key URLs**: Root redirects to mods listing; `/mods` for mod browsing, `/tools` for tool listings.

---

## Architecture & Data Flow

### Core Design Pattern: Firestore-Backed POROs
- **No database schema**: Uses Firestore as the single source of truth via Google Cloud SDK
- **Models** (`app/models/mod.rb`, `app/models/tool.rb`):
  - Use `ActiveModel::Model` (not ActiveRecord)
  - Include `Convertable` (URL transformation) and `Firestorable` (Firestore access) concerns
  - `.all` class method fetches and filters documents from Firestore collections
  - All data is immutable read-only; no persistence methods
- **Firestore Collections**: `mods` and `tools` collections contain documents with fields like `name`, `author`, `imageURL`, `fileURL`, `readmeURL`, etc.

### Data Transformation Concerns
- **`Firestorable`**: Initializes Google Cloud Firestore client using `Rails.application.credentials.firebase_keyfile`
- **`Convertable`**: Converts GitHub URLs to `raw.githubusercontent.com` for direct README fetching via `Net::HTTP`
  - Pattern: Maps `github.com` → `raw.githubusercontent.com` to retrieve markdown from repos

### Request Flow
1. Routes are scoped: `/mods/:author/:slug` (detail), `/mods/:author` (author listing), `/mods/` (all mods)
2. Controllers sanitize params with `sanitize()` before using in queries
3. In-memory searching/filtering: Controllers iterate over Mod or Tool results to match query/author/ID
4. Views render either full page or turbo-frame partial based on request type

---

## Key Files & Patterns

### Controllers (`app/controllers/`)
- **`ModsController`**: Handles search (`query` param), author filtering (`author` param), and redirect-by-ID logic
  - `.set_session` stores request URL for session context
  - Supports turbo-frame requests for search-in-place updates
- All controllers inherit from `ApplicationController` which includes sanitization helpers

### Models (`app/models/`)
- **`Mod`**:
  - `SORTKEYS = %w[author name]` (for future sorting, currently disabled)
  - Key methods: `readme` (fetches & strips first heading), `details` (readme or description fallback), `preferred_type` (pak > zip), `download_types` (pak/zip/exmodz filters)
- **`Tool`**: Similar structure; note `fileType` (singular) vs Mod's plural `files` object

### Views
- Uses Turbo for dynamic search/filtering without full page reloads
- Stimulus JS controllers for interactivity (`app/javascript/controllers/`)
- Tailwind CSS with custom Icarus color palette (`icarus-100` to `icarus-900`)

---

## Development Workflow

### Setup & Local Development
```bash
bin/setup              # Install gems, prepare DB (SQLite in dev)
bin/dev                # Start web server (port 3000) + Tailwind watcher using foreman
```

### Testing
- **Framework**: RSpec (Rails integration tests)
- **Factories**: FactoryBot defined in `spec/factories/`
- **Run tests**: `bin/rspec` or `bundle exec rspec spec/requests/mods_spec.rb`
- **Test database**: SQLite (transactional fixtures enabled)

### Code Quality
- **Linting**: `bundle exec rubocop` (RuboCop + Rails + RSpec plugins)
- **Security**: `brakeman` (static analysis), `bundler-audit` (dependency scanning)
- **All gems frozen with `frozen_string_literal: true`** at file top

### Deployment
- **Production Database**: PostgreSQL (configured in `config/database.yml`)
- **Credentials**: `config/credentials.yml.enc` holds Firebase key via `RAILS_MASTER_KEY`
- **Docker build** (`Dockerfile`): Pre-compiles assets with master key; runs on Cloud Run
- **Cloud Build** (`cloudbuild.yaml`): Builds Docker image, runs `rails db:migrate`, deploys to Cloud Run

---

## Critical Integration Points

1. **Google Cloud Credentials**: Firestore access requires `firebase_keyfile` in credentials; missing this breaks data loading
3. **URL Fetching**: README loading depends on network access and valid GitHub/direct URLs; failures silently fall back to descriptions
4. **Turbo Frames**: Search results render as partials if turbo_frame_request? is true; full page otherwise
5. **Session Tracking**: ModsController.set_session stores origin URL for potential back-link features

---

## Common Tasks for AI Agents

### Adding a New Controller Action
1. Define route in `config/routes.rb` (scoped under `/mods` or `/tools`)
2. Add action method in controller
3. Sanitize user inputs: `sanitize(params[:key])`
4. Return partial if `turbo_frame_request?`, else full view
5. Add RSpec request test in `spec/requests/`

### Modifying Data from Firestore
1. Update Firestore collection docs directly (no Rails migrations needed)
2. Add accessor to Mod.ATTRIBUTES or Tool.ATTRIBUTES if new field is needed
3. Update model's .all method to map Firestore field to attribute (watch camelCase vs snake_case!)

### Styling Changes
1. Update `config/tailwind.config.js` for new colors/fonts
2. Edit component views or CSS; Tailwind rebuilds on save with `bin/dev`
3. Custom brand colors use `icarus-*` prefix (e.g., `bg-icarus-500`)

### Adding Tests
1. Create factories in `spec/factories/` if needed (FactoryBot configured in `spec/support/factory_bot.rb`)
2. Write request specs in `spec/requests/` (auto-typed as RSpec Rails integration tests)
3. Run: `bundle exec rspec spec/requests/your_new_spec.rb`

---

## Gotchas & Design Decisions

- **No database migrations**: This is a read-only Firestore consumer; schema changes happen externally
- **In-memory filtering**: All search/sort happens in Ruby, not in queries; for large datasets, optimize model caching or add pagination
- **GitHub URL conversion**: Only converts github.com hosts; other markdown URL hosts are used as-is
- **Field name mismatches**: Firestore uses camelCase (imageURL, fileURL), models use snake_case (image_url, file_url)
- **Sanitization is critical**: Always sanitize URL params before regex matching or display to prevent injection
