source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"

gem "sassc-rails"

gem "bootstrap", "~> 5.3"

gem "devise"

# Comentado para usar pundit
# gem "cancancan", "~> 3.5"

gem "pundit", "~> 2.5"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire"s SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire"s modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Incluye validaciones no sólo a nivel de la aplicación sino también a nivel de la base de datos
gem "database_validations"

gem "cocoon"

# Static analysis for security vulnerabilities [https://brakemanscanner.org/]
gem "brakeman", require: false
gem "bundler-audit", require: false
gem "rack-attack", require: false

gem "kaminari"
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# OCR y análisis de imágenes
gem 'image_processing', '~> 1.2'
gem 'ruby-vips' # Procesamiento eficiente de imágenes
gem 'rtesseract' # OCR para extraer texto
gem 'mini_magick' # Manipulación de imágenes

# IA y Machine Learning (opcional pero recomendado)
# gem 'ruby-openai' # Para análisis avanzado con GPT # comentados en lo que decido su conveniencia
# gem 'aws-sdk-textract' # OCR en la nube (alternativa) # comentados en lo que decido su conveniencia

# Active Storage ya incluido en Rails 8

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

