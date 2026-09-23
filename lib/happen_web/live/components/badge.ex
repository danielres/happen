defmodule HappenWeb.Components.Badge do
  use HappenWeb, :html

  attr :member, :map, required: true

  def render(assigns) do
    ~H"""
    <span class={[
      "badge ",
      @member.available? && "bg-success",
      !@member.available? && "opacity-50"
    ]}>
      {@member.name}
    </span>
    """
  end
end
