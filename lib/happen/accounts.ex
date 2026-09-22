defmodule Happen.Accounts do
  use Ash.Domain, otp_app: :happen, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Happen.Accounts.Admin do
      define :get_admin, action: :get
      define :initialize_admin, action: :initialize, args: [:password, :password_confirmation]
    end

    resource Happen.Accounts.Invitation do
      define :create_invitation, action: :create
      define :destroy_invitation, action: :destroy
      define :disable_invitation, action: :disable
      define :enable_invitation, action: :enable
      define :get_enabled_invitation, action: :get_enabled, args: [:id]

      define :get_enabled_invitation_by_token_hash,
        action: :get_enabled_by_token_hash,
        args: [:token_hash]

      define :get_invitation, action: :read, get_by: [:id]
      define :list_enabled_invitations, action: :list_enabled
      define :list_invitations, action: :list

      define :update_invitation_shared_with,
        action: :update_shared_with,
        args: [:shared_with]
    end

    resource Happen.Accounts.Token
    resource Happen.Accounts.User
  end

  def authenticate_admin(password) when is_binary(password) do
    with {:ok, admin} <- get_admin(),
         true <- Bcrypt.verify_pass(password, admin.password_hash) do
      {:ok, admin}
    else
      _ -> {:error, :invalid_credentials}
    end
  end

  def authenticate_admin(_password), do: {:error, :invalid_credentials}

  def redeem_invitation(token) when is_binary(token) do
    token
    |> Happen.Accounts.InvitationToken.hash()
    |> get_enabled_invitation_by_token_hash()
  end

  def redeem_invitation(_token), do: {:error, :invalid_invitation}

  def invitation_token(%Happen.Accounts.Invitation{token_ciphertext: ciphertext}) do
    Happen.Accounts.InvitationToken.decrypt(ciphertext)
  end
end
