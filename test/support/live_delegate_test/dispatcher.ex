defmodule Happen.LiveDelegateTest.Dispatcher do
  use HappenWeb, :live_view
  use LiveDelegate

  alias Happen.LiveDelegateTest.Recipient

  delegate(:recipient, Recipient, info: [:source])

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div />
    """
  end
end
