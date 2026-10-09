defmodule Happen.Push.RoomSubscription do
  use Ash.Resource,
    otp_app: :happen,
    domain: Happen.Push,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "push_room_subscriptions"
    repo Happen.Repo

    references do
      reference :subscription, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :associate do
      accept [:room_name, :subscription_id]
      upsert? true
      upsert_identity :unique_subscription_room
      upsert_fields []
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :room_name, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :subscription, Happen.Push.Subscription do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_subscription_room, [:subscription_id, :room_name]
  end
end
