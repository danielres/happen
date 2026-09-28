defmodule HappenWeb.ExperimentsLive.Components.Header do
  use HappenWeb, :html

  alias HappenWeb.ExperimentsLive.Presences

  def render(assigns) do
    ~H"""
    <div class={[
      "flex justify-between gap-4 items-end",
      "bg-base-200 px-4 py-3 rounded-lg grow"
    ]}>
      <div class="font-bold opacity-40 truncate text-sm max-w-2/3">
        {@room.name}
      </div>

      <HappenWeb.Components.Dropdown.render id="user-dropdown">
        <:trigger class="cursor-pointer opacity-90 hover:opacity-100 transition">
          <HappenWeb.ExperimentsLive.User.badge data-testid="current-user-badge" user={@user} />
        </:trigger>

        <:pane class="bg-base-200 dropdown-end rounded-box">
          <ul class="menu w-40">
            <li class="bg-base-100">
              <.link data-testid="presences-leave" phx-click={Presences.leave_event()}>leave</.link>
            </li>
          </ul>
        </:pane>
      </HappenWeb.Components.Dropdown.render>
    </div>
    """
  end
end
