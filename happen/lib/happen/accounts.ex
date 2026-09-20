defmodule Happen.Accounts do
  use Ash.Domain, otp_app: :happen, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Happen.Accounts.Token
    resource Happen.Accounts.User
  end
end
