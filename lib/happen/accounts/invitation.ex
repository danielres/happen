defmodule Happen.Accounts.Invitation do
  use Ash.Resource,
    otp_app: :happen,
    domain: Happen.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "invitations"
    repo Happen.Repo
  end

  actions do
    defaults [:read]

    read :list do
      prepare build(sort: [created_at: :desc])
    end

    create :create do
      accept []

      change fn changeset, _context ->
        %{ciphertext: ciphertext, hash: hash} = Happen.Accounts.InvitationToken.generate()

        changeset
        |> Ash.Changeset.change_attribute(:token_ciphertext, ciphertext)
        |> Ash.Changeset.change_attribute(:token_hash, hash)
      end
    end

    update :update_shared_with do
      require_atomic? false
      accept [:shared_with]

      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :shared_with) do
          shared_with when is_binary(shared_with) ->
            Ash.Changeset.change_attribute(changeset, :shared_with, String.trim(shared_with))

          _shared_with ->
            changeset
        end
      end

      validate string_length(:shared_with, min: 1, max: 80)
    end

    update :disable do
      accept []
      change set_attribute(:disabled_at, &DateTime.utc_now/0)
    end

    update :enable do
      accept []
      change set_attribute(:disabled_at, nil)
    end

    destroy :destroy do
      validate attribute_does_not_equal(:disabled_at, nil)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :token_hash, :string do
      allow_nil? false
      sensitive? true
    end

    attribute :token_ciphertext, :string do
      allow_nil? false
      sensitive? true
    end

    attribute :shared_with, :string do
      allow_nil? false
      default "new group"
      public? true
    end

    attribute :disabled_at, :utc_datetime do
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_token_hash, [:token_hash]
  end
end
