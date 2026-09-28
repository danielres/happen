defmodule Happen.LiveDelegateTest.MountDispatcher do
  use HappenWeb, :live_view
  use LiveDelegate

  alias Happen.LiveDelegateTest.MountFirst
  alias Happen.LiveDelegateTest.MountSecond
  alias Happen.LiveDelegateTest.Recipient

  delegate(:first, MountFirst, events: false, info: false)
  delegate(:recipient, Recipient, info: false, mount: false)
  delegate(:second, MountSecond, events: false, info: false)

  def mount_delegates(socket, params, session) do
    socket |> delegate_mount(params, session)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div />
    """
  end
end
