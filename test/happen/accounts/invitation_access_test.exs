defmodule Happen.Accounts.InvitationAccessTest do
  use Happen.DataCase, async: true

  alias Happen.Accounts

  test "an enabled invitation can be redeemed by its secret token" do
    {:ok, invitation} = Accounts.create_invitation()
    {:ok, token} = Accounts.invitation_token(invitation)

    assert {:ok, redeemed} = Accounts.redeem_invitation(token)
    assert redeemed.id == invitation.id
  end

  test "a disabled invitation cannot be redeemed until it is enabled again" do
    {:ok, invitation} = Accounts.create_invitation()
    {:ok, token} = Accounts.invitation_token(invitation)
    {:ok, disabled_invitation} = Accounts.disable_invitation(invitation)

    assert {:error, _error} = Accounts.redeem_invitation(token)

    {:ok, _enabled_invitation} = Accounts.enable_invitation(disabled_invitation)

    assert {:ok, redeemed} = Accounts.redeem_invitation(token)
    assert redeemed.id == invitation.id
  end
end
