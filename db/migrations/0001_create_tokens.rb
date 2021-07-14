# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:tokens) do
      primary_key :id
      String :user, null: false
      String :token, null: false
      DateTime :created_at
    end
  end

  down do
    drop_table(:tokens)
  end
end
