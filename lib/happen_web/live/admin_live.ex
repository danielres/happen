defmodule HappenWeb.AdminLive do
  use HappenWeb, :live_view

  alias Happen.Accounts
  alias HappenWeb.LiveAccess

  def mount(_params, session, socket) do
    admin = load_admin()
    stage = admin_stage(admin, session["admin_id"])
    invitations = if stage == :authenticated, do: list_invitations(), else: []

    socket =
      socket
      |> assign(:admin, admin)
      |> assign(:edit_form, nil)
      |> assign(:editing_invitation, nil)
      |> assign(:login_form, to_form(%{"password" => ""}, as: :admin))
      |> assign(:setup_form, setup_form())
      |> assign(:stage, stage)
      |> stream(:invitations, invitations)

    {:ok, socket}
  end

  def handle_event(_event, _params, %{assigns: %{stage: stage}} = socket)
      when stage != :authenticated do
    {:noreply, put_flash(socket, :error, "Sign in to manage invitations")}
  end

  def handle_event("create-invitation", _params, socket) do
    case Accounts.create_invitation() do
      {:ok, invitation} ->
        {:noreply, stream_insert(socket, :invitations, invitation, at: 0)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not create invitation")}
    end
  end

  def handle_event("edit-invitation", %{"id" => id}, socket) do
    case Accounts.get_invitation(id) do
      {:ok, invitation} ->
        edit_form =
          invitation
          |> AshPhoenix.Form.for_update(:update_shared_with, as: "invitation")
          |> to_form()

        socket =
          socket
          |> assign(:edit_form, edit_form)
          |> assign(:editing_invitation, invitation)
          |> stream_insert(:invitations, invitation)

        {:noreply, socket}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Invitation not found")}
    end
  end

  def handle_event("save-invitation", %{"invitation" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.edit_form, params: params) do
      {:ok, invitation} ->
        socket =
          socket
          |> clear_editing()
          |> stream_insert(:invitations, invitation)

        {:noreply, socket}

      {:error, edit_form} ->
        socket =
          socket
          |> assign(:edit_form, edit_form)
          |> stream_insert(:invitations, socket.assigns.editing_invitation)

        {:noreply, socket}
    end
  end

  def handle_event("cancel-edit", _params, socket) do
    invitation = socket.assigns.editing_invitation

    socket =
      socket
      |> clear_editing()
      |> stream_insert(:invitations, invitation)

    {:noreply, socket}
  end

  def handle_event("disable-invitation", %{"id" => id}, socket) do
    with {:ok, invitation} <- Accounts.get_invitation(id),
         {:ok, invitation} <- Accounts.disable_invitation(invitation) do
      LiveAccess.revoke(invitation.id)
      {:noreply, stream_insert(socket, :invitations, invitation)}
    else
      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not update invitation")}
    end
  end

  def handle_event("enable-invitation", %{"id" => id}, socket) do
    update_invitation(socket, id, &Accounts.enable_invitation/1)
  end

  def handle_event("delete-invitation", %{"id" => id}, socket) do
    with {:ok, invitation} <- Accounts.get_invitation(id),
         :ok <- Accounts.destroy_invitation(invitation) do
      LiveAccess.revoke(invitation.id)
      {:noreply, stream_delete(socket, :invitations, invitation)}
    else
      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not delete invitation")}
    end
  end

  def handle_event("copy-invitation", %{"id" => id}, socket) do
    with {:ok, invitation} <- Accounts.get_invitation(id),
         {:ok, token} <- Accounts.invitation_token(invitation) do
      url = HappenWeb.Endpoint.url() <> "/invite/" <> token
      {:noreply, push_event(socket, "copy-invitation-url", %{url: url})}
    else
      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not copy invitation URL")}
    end
  end

  def handle_event("clipboard-result", %{"success" => true}, socket) do
    {:noreply, put_flash(socket, :info, "Invitation URL copied")}
  end

  def handle_event("clipboard-result", _params, socket) do
    {:noreply, put_flash(socket, :error, "Could not access the clipboard")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      mode={if(@stage == :authenticated, do: nil, else: "centered")}
    >
      <.form
        :if={@stage == :setup}
        for={@setup_form}
        action={~p"/_/setup"}
        class="grid w-80 gap-2"
        id="admin-setup-form"
        method="post"
      >
        <.input
          autocomplete="new-password"
          field={@setup_form[:password]}
          label="Set password"
          minlength="12"
          type="password"
        />
        <.input
          autocomplete="new-password"
          field={@setup_form[:password_confirmation]}
          label="Repeat password"
          minlength="12"
          type="password"
        />
        <.button type="submit">Set password</.button>
      </.form>

      <.form
        :if={@stage == :login}
        for={@login_form}
        action={~p"/_/login"}
        class="grid w-80 gap-2"
        id="admin-login-form"
        method="post"
      >
        <.input
          autocomplete="current-password"
          field={@login_form[:password]}
          label="Password"
          phx-mounted={JS.focus()}
          type="password"
        />
        <.button type="submit">Sign in</.button>
      </.form>

      <div
        :if={@stage == :authenticated}
        id="admin"
        phx-hook=".CopyToClipboard"
      >
        <header class="bg-base-300 flex items-center justify-between gap-4 p-4">
          <h1>Admin</h1>
          <.button href={~p"/_/logout"} id="admin-logout" method="delete">Log out</.button>
        </header>

        <section class="space-y-4 p-4">
          <h2 class="small-caps">Invitations</h2>
          <table class="table bg-base-300">
            <thead>
              <tr>
                <th class="w-0"><span class="sr-only">Status</span></th>
                <th class="w-0">created</th>
                <th>shared with</th>
                <th class="w-0">
                  <div class="flex justify-end">
                    <button
                      id="create-invitation"
                      class="btn btn-primary btn-sm btn-circle tooltip tooltip-primary tooltip-left"
                      data-tip="create new"
                      phx-click="create-invitation"
                      type="button"
                    >
                      <span class="sr-only">New invitation</span>
                      <.icon name="hero-plus-micro" />
                    </button>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody id="admin-invitations" phx-update="stream">
              <tr id="admin-invitations-empty" class="hidden only:table-row">
                <td colspan="4" class="text-center opacity-60">No invitations yet</td>
              </tr>
              <tr
                :for={{dom_id, invitation} <- @streams.invitations}
                id={dom_id}
                class="bg-base-200 py-2 px-4"
              >
                <td>
                  <button
                    :if={!invitation.disabled_at}
                    id={"disable-invitation-#{invitation.id}"}
                    class="btn btn-success btn-sm btn-circle tooltip tooltip-success tooltip-right"
                    data-testid="disable-invitation"
                    data-tip="disable invitation"
                    phx-click="disable-invitation"
                    phx-value-id={invitation.id}
                    type="button"
                  >
                    <span class="sr-only">Disable invitation</span>
                    <.icon name="hero-check-micro" />
                  </button>
                  <button
                    :if={invitation.disabled_at}
                    id={"enable-invitation-#{invitation.id}"}
                    class="btn btn-neutral btn-sm btn-circle tooltip tooltip-neutral tooltip-right"
                    data-tip="enable invitation"
                    phx-click="enable-invitation"
                    phx-value-id={invitation.id}
                    type="button"
                  >
                    <span class="sr-only">Enable invitation</span>
                    <.icon name="hero-minus-micro" />
                  </button>
                </td>
                <td class="whitespace-nowrap">
                  {Calendar.strftime(invitation.created_at, "%d %b %Y")}
                </td>
                <td>
                  <.form
                    :if={@editing_invitation && @editing_invitation.id == invitation.id}
                    for={@edit_form}
                    class="join"
                    id={"edit-invitation-#{invitation.id}"}
                    phx-submit="save-invitation"
                  >
                    <.input
                      class="input input-sm join-item w-full"
                      field={@edit_form[:shared_with]}
                      phx-key="Escape"
                      phx-keydown="cancel-edit"
                      phx-mounted={JS.focus()}
                    />
                    <button class="btn btn-sm btn-primary join-item" type="submit">
                      <.icon name="hero-check-micro" />
                      <span class="sr-only">Save</span>
                    </button>
                    <button
                      class="btn btn-sm btn-neutral join-item"
                      phx-click="cancel-edit"
                      type="button"
                    >
                      <.icon name="hero-x-mark-micro" />
                      <span class="sr-only">Cancel</span>
                    </button>
                  </.form>
                  <button
                    :if={!@editing_invitation || @editing_invitation.id != invitation.id}
                    id={"edit-invitation-label-#{invitation.id}"}
                    class="underline decoration-dashed underline-offset-4 decoration-base-content/50 tooltip cursor-pointer"
                    data-tip="edit description"
                    phx-click="edit-invitation"
                    phx-value-id={invitation.id}
                    type="button"
                  >
                    {invitation.shared_with}
                  </button>
                </td>
                <td>
                  <div class="flex justify-end">
                    <button
                      :if={!invitation.disabled_at}
                      id={"copy-invitation-#{invitation.id}"}
                      class="btn btn-primary btn-sm btn-circle tooltip tooltip-primary tooltip-left"
                      data-tip="copy secret url"
                      phx-click="copy-invitation"
                      phx-value-id={invitation.id}
                      type="button"
                    >
                      <.icon name="hero-document-duplicate-micro" />
                      <span class="sr-only">Copy URL</span>
                    </button>
                    <button
                      :if={invitation.disabled_at}
                      id={"delete-invitation-#{invitation.id}"}
                      class="btn btn-error btn-sm btn-circle tooltip tooltip-error tooltip-left"
                      data-confirm="Delete this invitation permanently?"
                      data-tip="delete permanently"
                      phx-click="delete-invitation"
                      phx-value-id={invitation.id}
                      type="button"
                    >
                      <span class="sr-only">Delete invitation</span>
                      <.icon name="hero-trash-micro" />
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </section>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyToClipboard">
        export default {
          mounted() {
            this.handleEvent("copy-invitation-url", ({url}) => {
              if (!navigator.clipboard) {
                this.pushEvent("clipboard-result", {success: false})
                return
              }

              navigator.clipboard.writeText(url)
                .then(() => this.pushEvent("clipboard-result", {success: true}))
                .catch(() => this.pushEvent("clipboard-result", {success: false}))
            })
          }
        }
      </script>
    </Layouts.app>
    """
  end

  defp admin_stage(nil, _session_admin_id), do: :setup
  defp admin_stage(%{id: admin_id}, admin_id), do: :authenticated
  defp admin_stage(_admin, _session_admin_id), do: :login

  defp clear_editing(socket) do
    socket
    |> assign(:edit_form, nil)
    |> assign(:editing_invitation, nil)
  end

  defp list_invitations do
    case Accounts.list_invitations() do
      {:ok, invitations} -> invitations
      {:error, _error} -> []
    end
  end

  defp load_admin do
    case Accounts.get_admin() do
      {:ok, admin} -> admin
      {:error, _error} -> nil
    end
  end

  defp setup_form do
    to_form(
      %{"password" => "", "password_confirmation" => ""},
      as: :admin
    )
  end

  defp update_invitation(socket, id, update) do
    with {:ok, invitation} <- Accounts.get_invitation(id),
         {:ok, invitation} <- update.(invitation) do
      {:noreply, stream_insert(socket, :invitations, invitation)}
    else
      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not update invitation")}
    end
  end
end
