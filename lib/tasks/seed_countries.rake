# lib/tasks/seed_countries.rake
namespace :seed do
  desc "Cargar solo países desde CSV a la tabla countries"
  task countries: :environment do
    require "csv"

    csv_path = Rails.root.join("db/data/countries.csv")
    unless File.exist?(csv_path)
      puts "⚠️  No se encontró #{csv_path}"
      exit 1
    end

    puts "🌍 Cargando países desde #{csv_path}..."

    CSV.foreach(csv_path, headers: true) do |row|
      alpha2 = row["alpha2"] || row["Alpha-2"] || row["code2"]
      alpha3 = row["alpha3"] || row["Alpha-3"] || row["code3"]
      name   = row["name"]   || row["Name"]

      next if alpha2.blank? || name.blank?

      Country.find_or_create_by!(alpha2_code: alpha2.strip.upcase) do |c|
        c.name        = name.strip
        c.alpha3_code = alpha3&.strip&.upcase
        c.nationality = row["nationality"]&.strip
      end
    end

    puts "✅ Países cargados: #{Country.count}"
  end
end

