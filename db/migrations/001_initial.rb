# frozen_string_literal: true

# http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html

Sequel.migration do
  up do
    create_table(:rides) do
      uuid :id, primary_key: true
      uuid :adminuuid, unique: true
      DateTime :created_at
      DateTime :updated_at
      Date :date, null: false
      String :time, size: 255, null: false
      String :title, size: 255,  null: false
      String :description
    end
    create_table(:seats) do
      uuid :id, primary_key: true
      String :name, size: 255
      TrueClass :free, :default => true
      foreign_key :ride_id, :rides, {:type => :uuid}
    end
    create_table(:messages) do
      uuid :id, primary_key: true
      DateTime :created_at
      String :msg, size: 255, null: false
      foreign_key :ride_id, :rides, {:type => :uuid}
    end
  end
end
