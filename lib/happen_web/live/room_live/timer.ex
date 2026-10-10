defmodule HappenWeb.RoomLive.Timer do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:timer]

  alias HappenWeb.RoomLive.Timer.Button
  alias HappenWeb.RoomLive.Timer.State

  delegate(:button, Button, mount: false, info: false)
  delegate(:state, State, events: false, mount: false, info: false)

  @options [10, 20, 30, 45, 60, 90, 120, 180, 240, 360]

  def on_mount(_params, _session, socket) do
    default_deadline = DateTime.now!("Etc/UTC") |> DateTime.add(15, :minute)

    socket
    |> delegate_assign(%{options: @options})
    |> State.set_deadline(default_deadline)
    |> State.schedule_tick()
  end

  def handle_event("set_deadline", %{"option" => option}, socket) do
    {option, ""} = Integer.parse(option)
    deadline = DateTime.now!("Etc/UTC") |> DateTime.add(option, :minute)

    socket =
      socket
      |> State.set_deadline(deadline)
      |> assign(view: "main")
      |> Button.store_deadline(deadline)

    {:noreply, socket}
  end

  def handle_info(:tick, socket), do: {:noreply, State.tick(socket)}

  def render_button(assigns), do: Button.render(assigns)

  attr :timer, :map, required: true
  attr :tz, :string, required: true

  def render_deadline(assigns) do
    ~H"""
    <div class={[
      "self-baseline",
      "flex justify-end gap-1 items-center",
      "text-xs"
    ]}>
      <span class="opacity-60">Available until:</span>
      <span class="bg-base-300 px-2 py-0.5 rounded-lg text-[12px]">
        {@timer.deadline |> format_min_remaining(@tz)}
      </span>
    </div>
    """
  end

  attr :timer, :map, required: true

  def render_form(assigns) do
    ~H"""
    <div class="bg-base-200 rounded-box p-1">
      <div class="grid gap-1">
        <button
          :for={option <- @timer.options}
          class="btn btn-sm bg-info/30 hover:bg-info/50 transition border-none text-base-content/80"
          phx-click={delegate_event("set_deadline")}
          phx-value-option={option}
          type="button"
        >
          <span :if={option < 120}>{option} min</span>
          <span :if={option >= 120}>{div(option, 60)} hours</span>
        </button>

        <button
          type="button"
          phx-click="toggle_view"
          phx-value-view="timer"
          class={[
            "btn btn-sm bg-base-100/50 hover:bg-base-100 text-base-content/80"
          ]}
        >
          Cancel
        </button>
      </div>
    </div>
    """
  end

  defp format_min_remaining(datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, local_datetime} ->
        Calendar.strftime(local_datetime, " %H:%M")

      {:error, _reason} ->
        Calendar.strftime(datetime, "%H:%M UTC")
    end
  end
end
