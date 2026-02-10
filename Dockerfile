# syntax=docker/dockerfile:1

# Stage 1: Build
FROM ruby:3.4-bookworm AS build

WORKDIR /rails

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && \
    bundle config set --local without "development test" && \
    bundle install && \
    rm -rf ~/.bundle/cache

# Copy application code
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# Stage 2: Runtime
FROM ruby:3.4-slim-bookworm

WORKDIR /rails

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libsqlite3-0 curl && \
    rm -rf /var/lib/apt/lists/*

# Set production environment
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# Run as non-root user
RUN groupadd --system rails --gid 1000 && \
    useradd rails --system --uid 1000 --gid 1000 --home /rails && \
    mkdir -p tmp/pids tmp/cache tmp/sockets && \
    chown -R rails:rails /tmp

# Copy built artifacts from build stage
COPY --chown=rails:rails --from=build /rails /rails
COPY --chown=rails:rails --from=build /usr/local/bundle /usr/local/bundle

USER rails:rails

ENTRYPOINT ["/rails/docker-entrypoint.sh"]
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]

