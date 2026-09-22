defmodule HappenWeb.AdminLive do
  use HappenWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, fake_date} = Date.new(2025, 11, 09)

    invitations = [
      %{
        value: "xxx",
        inserted_at: fake_date,
        disabled_at: fake_date,
        shared_with: "Friends group1"
      },
      %{
        value: "yyy",
        inserted_at: fake_date,
        disabled_at: nil,
        shared_with: "Friends group2"
      }
    ]

    socket =
      socket
      |> assign(invitations: invitations)
      |> assign(stage: :authenticated)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app :if={@stage == :setup} mode="centered" flash={@flash}>
      <form class="grid">
        <.input name="password" label="set password" value="" type="password" />
        <.input name="password_repeat" label="repeat" value="" type="password" />
        <.button type="submit">Submit</.button>
      </form>
    </Layouts.app>

    <Layouts.app :if={@stage == :login} mode="centered" flash={@flash}>
      <form class="grid">
        <.input name="password" label="password" value="" type="password" />
        <.button type="submit">Submit</.button>
      </form>
    </Layouts.app>

    <Layouts.app :if={@stage == :authenticated} flash={@flash}>
      <div>
        <header class="bg-base-300 p-4">Admin</header>

        <section class="space-y-4 p-4">
          <h3 class="small-caps">Invitations</h3>
          <table class="table bg-base-300">
            <thead>
              <tr>
                <th class="w-0"></th>
                <th class="w-0">created</th>
                <th>shared with</th>
                <th class="w-0">
                  <div class="flex justify-end">
                    <button
                      class="btn btn-primary btn-sm btn-circle tooltip tooltip-primary tooltip-left"
                      data-tip="create new"
                    >
                      <span class="sr-only">New</span>
                      <.icon name="hero-plus-micro" />
                    </button>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr :for={invitation <- @invitations} class="bg-base-200 py-2 px-4">
                <td>
                  <button
                    :if={!invitation.disabled_at}
                    class="btn btn-success btn-sm btn-circle tooltip tooltip-success tooltip-right"
                    data-tip="enabled"
                  >
                    <span class="sr-only">enabled</span>
                    <.icon name="hero-check-micro" />
                  </button>
                  <button
                    :if={invitation.disabled_at}
                    class="btn btn-neutral btn-sm btn-circle tooltip tooltip-neutral tooltip-right"
                    data-tip="disabled"
                  >
                    <span class="sr-only">disabled</span>
                    <.icon name="hero-minus-micro" />
                  </button>
                </td>
                <td class="whitespace-nowrap">
                  {Calendar.strftime(invitation.inserted_at, "%d %b %Y")}
                </td>
                <td>
                  <button
                    class="underline decoration-dashed underline-offset-4 decoration-base-content/50 tooltip cursor-pointer"
                    data-tip="edit description"
                  >
                    {invitation.shared_with}
                  </button>
                </td>
                <td>
                  <div class="flex justify-end">
                    <button
                      :if={!invitation.disabled_at}
                      class="btn btn-primary btn-sm btn-circle tooltip tooltip-primary tooltip-left"
                      data-tip="copy secret url"
                    >
                      <.icon name="hero-document-duplicate-micro" />
                      <span class="sr-only">copy url</span>
                    </button>
                    <button
                      :if={invitation.disabled_at}
                      class="btn btn-error btn-sm btn-circle tooltip tooltip-error tooltip-left"
                      data-tip="delete permanently"
                    >
                      <span class="sr-only">delete</span>
                      <.icon name="hero-trash-micro" />
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
