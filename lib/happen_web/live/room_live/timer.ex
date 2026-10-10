defmodule HappenWeb.RoomLive.Timer do
  use HappenWeb, :live_view
  use LiveDelegate, path: [:timer]

  def on_mount(_params, _session, socket) do
    until = DateTime.now!("Etc/UTC") |> DateTime.add(15, :minute)
    options = [5, 10, 20, 30, 45, 60, 90, 120, 180, 240, 360]

    socket
    |> delegate_assign(%{until: until, options: options})
  end

  def handle_event("set", %{"option" => option}, socket) do
    {option, _} = Integer.parse(option)
    until = DateTime.now!("Etc/UTC") |> DateTime.add(option, :minute)

    socket =
      socket
      |> delegate_assign(:until, until)
      |> assign(view: "main")

    {:noreply, socket}
  end

  def diff(date_time) do
    now = DateTime.now!("Etc/UTC")
    DateTime.diff(date_time, now, :minute)
  end

  def render_remaining(assigns) do
    ~H"""
    <div class={[
      "self-baseline",
      "flex justify-end gap-1 items-center",
      "text-xs"
    ]}>
      <span class="opacity-60">Available until:</span>
      <span class="bg-base-300 px-2 py-0.5 rounded-lg text-[12px]">
        {@timer.until |> format_min_remaining(@tz)}
      </span>
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

  def render_button(assigns) do
    assigns = assigns |> assign(value: diff(assigns.timer.until))

    ~H"""
    <button
      phx-click="toggle_view"
      phx-value-view="timer"
      class={[
        "bg-base-100",
        "opacity-80 hover:opacity-100 transition",
        "cursor-pointer",
        "badge",
        "rounded-full gap-1",
        "text-[12px] font-semibold",
        "oldstyle-nums"
      ]}
      type="button"
    >
      {@value}
      <.icon name="hero-clock-micro" class="size-3" />
    </button>
    """
  end

  def render_form(assigns) do
    ~H"""
    <div class="bg-base-200 rounded-box p-1">
      <div class="grid gap-1">
        <button
          :for={option <- @timer.options}
          class="btn btn-sm btn-info btn-soft text-base-content/80"
          phx-click={delegate_event("set")}
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
            "btn btn-sm btn-soft hover:bg-base-100 text-base-content/80"
          ]}
        >
          Cancel
        </button>
      </div>
    </div>
    """
  end
end
