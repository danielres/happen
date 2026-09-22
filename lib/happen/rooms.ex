defmodule Happen.Rooms do
  use Ash.Domain,
    otp_app: :happen,
    extensions: [AshAdmin.Domain, AshPhoenix]

  admin do
    show? true
  end

  resources do
    resource Happen.Rooms.Room do
      define :create_room, args: [:name]
    end
  end
end
