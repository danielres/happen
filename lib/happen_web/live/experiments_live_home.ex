defmodule HappenWeb.ExperimentsLiveHome do
  use HappenWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app mode="centered" flash={@flash}>
      <div class="bg-base-200 p-4 rounded-box">
        Hello, are you lost?
      </div>
    </Layouts.app>
    """
  end
end
