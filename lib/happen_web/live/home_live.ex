defmodule HappenWeb.HomeLive do
  use HappenWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, username: nil, members: [])}
  end

  def handle_event("join", %{"username" => username}, socket) do
    :ok = Group.join(:happen, "chat/room/42", %{username: username})
    members = Group.members(:happen, "chat/room/42")

    {:noreply, assign(socket, username: username, members: members)}
  end

  def render(assigns) do
    ~H"""
    <%= if @username do %>
      <p>Joined as {@username}</p>
    <% else %>
      <form phx-submit="join">
        <input type="text" class="input" name="username" placeholder="Enter your name" />
        <button class="btn" type="submit">Join room</button>
      </form>
    <% end %>

    <ul>
      <li :for={{_pid, meta} <- @members}>{meta.username}</li>
    </ul>
    """
  end
end
