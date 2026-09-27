defmodule LiveDelegate do
  @moduledoc """
  Generates LiveView event and message delegation for registered feature modules.

  Delegated events use a `"namespace:event"` name. Delegated process messages
  use tuples whose first element is a registered tag; the remaining elements
  are normalized into one payload passed to `handle_info/2`.
  """

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [delegate: 2, delegate: 3]

      Module.register_attribute(__MODULE__, :live_delegates, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro delegate(name, module_ast, opts \\ []) when is_atom(name) do
    module = Macro.expand(module_ast, __CALLER__)
    events? = Keyword.get(opts, :events, true)

    info_tags =
      case Keyword.get(opts, :info, [name]) do
        false -> []
        tags -> List.wrap(tags)
      end

    quote bind_quoted: [
            name: name,
            module: module,
            events?: events?,
            info_tags: info_tags
          ] do
      @live_delegates {name, module, events?, info_tags}
    end
  end

  defmacro __before_compile__(env) do
    delegates =
      env.module
      |> Module.get_attribute(:live_delegates)
      |> Enum.reverse()

    event_modules =
      for {name, module, true, _info_tags} <- delegates, into: %{} do
        {Atom.to_string(name), module}
      end

    info_modules =
      for {_name, module, _events?, info_tags} <- delegates,
          info_tag <- info_tags,
          into: %{} do
        {info_tag, module}
      end

    quote do
      @live_delegate_event_modules unquote(Macro.escape(event_modules))
      @live_delegate_info_modules unquote(Macro.escape(info_modules))

      @impl Phoenix.LiveView
      def handle_event(event, payload, socket) do
        [provenance, delegated_event] = String.split(event, ":", parts: 2)
        module = Map.fetch!(@live_delegate_event_modules, provenance)

        module.handle_event(delegated_event, payload, socket)
      end

      @impl Phoenix.LiveView
      def handle_info(message, socket) when is_tuple(message) and tuple_size(message) > 0 do
        [provenance | payload_parts] = Tuple.to_list(message)
        module = Map.fetch!(@live_delegate_info_modules, provenance)

        payload =
          case payload_parts do
            [single_payload] -> single_payload
            multiple_parts -> List.to_tuple(multiple_parts)
          end

        module.handle_info(payload, socket)
      end
    end
  end
end
