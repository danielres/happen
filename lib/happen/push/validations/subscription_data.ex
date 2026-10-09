defmodule Happen.Push.Validations.SubscriptionData do
  use Ash.Resource.Validation

  @allowed_hosts [
    "fcm.googleapis.com",
    "push.services.mozilla.com",
    "updates.push.services.mozilla.com",
    "web.push.apple.com"
  ]

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def supports(_opts), do: [Ash.Changeset]

  @impl true
  def validate(changeset, _opts, _context) do
    with :ok <- validate_endpoint(Ash.Changeset.get_attribute(changeset, :endpoint)),
         :ok <- validate_key(changeset, :p256dh, 65),
         :ok <- validate_key(changeset, :auth, 16) do
      :ok
    end
  end

  defp validate_endpoint(endpoint) do
    uri = URI.parse(endpoint || "")

    if uri.scheme == "https" and uri.host in @allowed_hosts and is_binary(uri.path) and
         uri.userinfo == nil do
      :ok
    else
      {:error, field: :endpoint, message: "must use a supported Web Push provider"}
    end
  end

  defp validate_key(changeset, attribute, expected_size) do
    value = Ash.Changeset.get_attribute(changeset, attribute)

    case Base.url_decode64(value || "", padding: false) do
      {:ok, <<4, _rest::binary>> = decoded}
      when attribute == :p256dh and byte_size(decoded) == expected_size ->
        :ok

      {:ok, decoded} when attribute != :p256dh and byte_size(decoded) == expected_size ->
        :ok

      _error ->
        {:error,
         field: attribute, message: "must be a valid #{expected_size}-byte Web Push key"}
    end
  end
end
