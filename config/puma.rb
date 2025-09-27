
# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL.

# Configuración de workers y threads para desarrollo
workers Integer(ENV["WEB_CONCURRENCY"] || 0)
threads_count = Integer(ENV["RAILS_MAX_THREADS"] || 3)
threads threads_count, threads_count

# Bind a todas las interfaces para acceso externo
# config/puma.rb
if Rails.env.development?
  ssl_bind "0.0.0.0", "3001", {
    key: "localhost+3-key.pem",
    cert: "localhost+3.pem"
  }
  bind "tcp://0.0.0.0:3000"  # HTTP también disponible
else
  bind "tcp://127.0.0.1:3000"
end

# bind 'tcp://0.0.0.0:3000'

# Configuración de ambiente
environment ENV.fetch("RAILS_ENV", "development")

# Plugin para reinicio con bin/rails restart
plugin :tmp_restart

# Plugin para Solid Queue si está habilitado
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Archivo PID solo si se especifica
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

# Precargar aplicación solo en modo cluster (workers > 0)
preload_app! if Integer(ENV["WEB_CONCURRENCY"] || 0) > 0

# Hook para workers (solo si hay workers)
if Integer(ENV["WEB_CONCURRENCY"] || 0) > 0
  on_worker_boot do
    ActiveRecord::Base.establish_connection
  end
end
