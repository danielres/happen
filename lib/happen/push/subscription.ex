defmodule Happen.Push.Subscription do
  use Ash.Resource,
    otp_app: :happen,
    domain: Happen.Push,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "push_subscriptions"
    repo Happen.Repo

    references do
      reference :invitation, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy]

    create :sync do
      accept [:auth, :endpoint, :guest_id, :invitation_id, :p256dh]
      upsert? true
      upsert_identity :unique_endpoint
      upsert_fields [:auth, :guest_id, :invitation_id, :p256dh, :updated_at]
    end
  end

  validations do
    validate {Happen.Push.Validations.SubscriptionData, []} do
      on [:create, :update]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :endpoint, :string do
      allow_nil? false
      public? true
      sensitive? true
    end

    attribute :guest_id, :uuid do
      allow_nil? false
      public? true
    end

    attribute :p256dh, :string do
      allow_nil? false
      public? true
      sensitive? true
    end

    attribute :auth, :string do
      allow_nil? false
      public? true
      sensitive? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :invitation, Happen.Accounts.Invitation do
      allow_nil? true
      public? true
    end

    has_many :room_subscriptions, Happen.Push.RoomSubscription
  end

  identities do
    identity :unique_endpoint, [:endpoint]
  end
end
