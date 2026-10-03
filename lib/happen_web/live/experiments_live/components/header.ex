defmodule HappenWeb.ExperimentsLive.Components.Header do
  use HappenWeb, :html

  alias HappenWeb.Components.Dropdown
  alias HappenWeb.ExperimentsLive.Presences
  alias HappenWeb.ExperimentsLive.User

  def render(assigns) do
    ~H"""
    <div class={[
      "flex justify-between gap-4 items-end",
      "bg-base-200 px-4 py-3 rounded-lg grow"
    ]}>
      <div data-testid="room-name" class="font-bold opacity-40 truncate text-sm max-w-2/3">
        {@room.name}
      </div>

      <Dropdown.render id="user-dropdown">
        <:trigger class="cursor-pointer opacity-90 hover:opacity-100 transition">
          <User.badge data-testid="current-user-badge" user={@user} />
        </:trigger>

        <:pane class="bg-base-200 dropdown-end rounded-box">
          <ul class="menu w-40">
            <li class="bg-base-100">
              <.link data-testid="presences-leave" phx-click={Presences.leave_event()}>leave</.link>
            </li>
          </ul>
        </:pane>
      </Dropdown.render>
    </div>
    """
  end
end
