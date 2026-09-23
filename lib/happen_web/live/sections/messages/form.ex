defmodule HappenWeb.Sections.Messages.Form do
  use HappenWeb, :html

  def render(assigns) do
    ~H"""
    <form
      id="message-form"
      class="join grid shrink-0 grid-cols-[1fr_auto] bg-base-300 p-4"
      phx-hook=".ClearMessage"
      phx-submit="say"
      phx-update="ignore"
    >
      <input
        id="message-input"
        class="join-item input w-full input-primary"
        type="text"
        name="message"
        placeholder="Say something"
        phx-mounted={JS.focus()}
      />

      <.button
        id="message-submit"
        class="join-item btn btn-primary"
        type="submit"
        phx-hook=".DisableWhenEmpty"
        disabled
      >
        <.icon name="hero-paper-airplane -rotate-45" />
        <span class="sr-only">Say</span>
      </.button>
    </form>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ClearMessage">
      export default {
        mounted() {
          this.input = this.el.elements.message
          this.handleEvent("message-sent", () => {
            this.el.reset()
            this.input.dispatchEvent(new Event("input"))
          })
        }
      }
    </script>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".DisableWhenEmpty">
      export default {
        mounted() {
          this.input = this.el.form.elements.message
          this.syncDisabled = () => {
            this.el.disabled = this.input.value.trim() === ""
          }

          this.input.addEventListener("input", this.syncDisabled)
          this.syncDisabled()
        },

        destroyed() {
          this.input.removeEventListener("input", this.syncDisabled)
        }
      }
    </script>
    """
  end
end
