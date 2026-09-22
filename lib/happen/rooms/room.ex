defmodule Happen.Rooms.Room do
  use Ash.Resource,
    otp_app: :happen,
    domain: Happen.Rooms,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAdmin.Domain, AshPhoenix]

  postgres do
    table "rooms"
    repo Happen.Repo
  end

  actions do
    defaults [:read]

    create :create_room do
      accept [:name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end
end
