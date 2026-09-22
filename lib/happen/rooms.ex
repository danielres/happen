defmodule Happen.Rooms do
  use Ash.Domain, otp_app: :happen, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Happen.Rooms.Room
  end
end
