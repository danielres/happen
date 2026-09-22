defmodule HappenWeb.Components.Badge do
  use HappenWeb, :html

  attr :member, :map, required: true

  def render(assigns) do
    ~H"""
    <span class={[
      "badge ",
      @member.available? && "bg-success",
      !@member.available? && "bg-warning"
    ]}>
      {@member.name}
    </span>
    """
  end
end
