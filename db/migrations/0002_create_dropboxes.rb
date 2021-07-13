# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:dropboxes) do
      primary_key :id
      String :path, null: false
      String :user
      Boolean :processed, default: false
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table(:dropboxes)
  end
end
