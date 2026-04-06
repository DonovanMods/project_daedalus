# frozen_string_literal: true

# Puma configuration for Rails 8
#
# Threads: min/max thread count per worker.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Port to listen on (default 3000).
port ENV.fetch("PORT", 3000)

# Environment
environment ENV.fetch("RAILS_ENV", "development")

# PID file
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Allow longer worker timeout in development.
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside Puma for single-server deployments.
plugin :solid_queue if ENV.fetch("RAILS_ENV", "development") == "production"
