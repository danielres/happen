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
      define :get_invitation, action: :read, get_by: [:id]
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

  def invitation_token(%Happen.Accounts.Invitation{token_ciphertext: ciphertext}) do
    Happen.Accounts.InvitationToken.decrypt(ciphertext)
  end
end
