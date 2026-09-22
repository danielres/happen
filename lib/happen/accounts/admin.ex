defmodule Happen.Accounts.Admin do
  use Ash.Resource,
    otp_app: :happen,
    domain: Happen.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "admins"
    repo Happen.Repo
  end

  actions do
    defaults [:read]

    read :get do
      get? true
      filter expr(singleton_key == "admin")
    end

    create :initialize do
      accept []

      argument :password, :string do
        allow_nil? false
        sensitive? true
        constraints min_length: 12, max_length: 128
      end

      argument :password_confirmation, :string do
        allow_nil? false
        sensitive? true
      end

      validate confirm(:password, :password_confirmation)

      change fn changeset, _context ->
        case Ash.Changeset.get_argument(changeset, :password) do
          password when is_binary(password) ->
            Ash.Changeset.change_attribute(
              changeset,
              :password_hash,
              Bcrypt.hash_pwd_salt(password)
            )

          _password ->
            changeset
        end
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :singleton_key, :string do
      allow_nil? false
      default "admin"
    end

    attribute :password_hash, :string do
      allow_nil? false
      sensitive? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :singleton, [:singleton_key]
  end
end
