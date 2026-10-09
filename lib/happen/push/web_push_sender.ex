defmodule Happen.Push.WebPushSender do
  @behaviour Happen.Push.Sender

  @impl true
  def send(subscription, payload) do
    subscription = %WebPushEx.Subscription{
      endpoint: URI.parse(subscription.endpoint),
      keys: %{auth: subscription.auth, p256dh: subscription.p256dh}
    }

    request = WebPushEx.request(subscription, payload |> :json.encode() |> to_string())

    options =
      [
        body: request.body,
        connect_options: [timeout: 5_000],
        headers: request.headers,
        receive_timeout: 5_000,
        redirect: false,
        retry: false
      ]
      |> Keyword.merge(config()[:req_options] || [])

    case Req.post(request.endpoint, options) do
      {:ok, %{status: status}} when status in 200..299 -> :ok
      {:ok, %{status: status}} when status in [404, 410] -> :expired
      {:ok, %{status: status}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp config, do: Application.get_env(:happen, __MODULE__, [])
end
