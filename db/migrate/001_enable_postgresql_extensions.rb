class EnablePostgresqlExtensions < ActiveRecord::Migration[8.0]
    def up
      # Extensiones esenciales para Rails moderno
      enable_extension 'plpgsql' unless extension_enabled?('plpgsql')
      enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
      enable_extension 'btree_gin' unless extension_enabled?('btree_gin')
      enable_extension 'uuid-ossp' unless extension_enabled?('uuid-ossp')
      enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
      enable_extension 'unaccent' unless extension_enabled?('unaccent')
      enable_extension 'citext' unless extension_enabled?('citext')
      
      puts "✅ Extensiones PostgreSQL habilitadas correctamente"
    end
  
    def down
      # No deshabilitamos extensiones en rollback por seguridad
      # disable_extension 'pg_trgm'
      # disable_extension 'btree_gin'
      # etc...
    end
  end