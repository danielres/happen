defmodule Happen.Push.Sender do
  @callback send(Happen.Push.Subscription.t(), map()) ::
              :ok | :expired | {:error, term()}
end
