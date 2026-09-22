defmodule HappenWeb.Sections.Messages do
  use HappenWeb, :html

  attr :messages, :list, required: true

  def render(assigns) do
    ~H"""
    <ul
      id="messages"
      class="min-h-0 flex-1 space-y-1 overflow-y-auto"
      phx-hook=".AutoScroll"
    >
      <li :for={message <- @messages} class="bg-base-200 py-2 px-4">
        <div class="text-sm opacity-50">{message.member.name}</div>
        <div>{message.body}</div>
      </li>
    </ul>

    <form
      id="message-form"
      class="join grid shrink-0 grid-cols-[1fr_auto]"
      phx-hook=".ClearMessage"
      phx-submit="say"
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
          this.handleEvent("message-sent", () => {
            this.el.reset()
            this.el.elements.message.dispatchEvent(new Event("input"))
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

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AutoScroll">
      export default {
        mounted() {
          this.scrollToBottom()
        },

        beforeUpdate() {
          this.followingLatest =
            this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 64
        },

        updated() {
          if (this.followingLatest) this.scrollToBottom()
        },

        scrollToBottom() {
          this.el.scrollTop = this.el.scrollHeight
        }
      }
    </script>
    """
  end
end
