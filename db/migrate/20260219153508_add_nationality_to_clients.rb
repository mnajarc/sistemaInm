class AddNationalityToClients < ActiveRecord::Migration[8.0]
  def change

    add_reference :clients, :nationality_country, foreign_key: { to_table: :countries }
    add_reference :clients, :birth_country,       foreign_key: { to_table: :countries }


  end
end
