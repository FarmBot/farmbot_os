defmodule Farmbot.StateTracker do
  @moduledoc """
    Common functionality for modules that need to track
    simple states that can be easily represented as a struct with key value
    pairs.
  """
  @callback load(any) :: {:ok, map}
  defmacro __using__(name: name, model: model) do
    quote do
      alias Farmbot.ConfigStorage, as: FBConfigStorage
      defmodule State, do: defstruct unquote(model)

      defp get_config(:all) do
        GenServer.call(FBConfigStorage, {:get, unquote(name), :all})
      end

      defp get_config(key) do
        GenServer.call(FBConfigStorage, {:get, unquote(name), key})
      end

      defp put_config(key, value) do
        GenServer.cast(FBConfigStorage, {:put, unquote(name), {key, value}})
      end

      @doc """
        Starts a #{unquote(name)} state tracker.
      """
      def start_link(), do: start_link([])
      def start_link(args),
        do: GenServer.start_link(unquote(name), args, name: unquote(name))

      def init(args) do
        n = Module.split(unquote(name)) |> List.last
        Logger.debug ">> is starting #{n}."
        case load(args) do
          {:ok, %State{} = state} ->
            {:ok, broadcast(state)}
          {:error, reason} ->
            Logger.error ">> encountered an error starting #{n}" <>
              "#{inspect reason}"
            Farmbot.factory_reset
          err ->
            Logger.error ">> encountered an unknown error in #{n}"
            <> ": #{inspect err}"
            Farmbot.factory_reset
        end
      end

      # this should be overriden.
      def load(_args), do: {:ok, %State{}}

      defp dispatch(reply, %unquote(name).State{} = state) do
        broadcast(state)
        {:reply, reply, state}
      end

      # If something bad happens in this module it's usually non recoverable.
      defp dispatch(_, {:error, reason}), do: dispatch({:error, reason})

      defp dispatch(%unquote(name).State{} = state) do
        broadcast(state)
        {:noreply, state}
      end

      defp dispatch({:error, reason}) do
        Logger.error ">> encountered a fatal error in #{unquote(name)}."
        Farmbot.factory_reset
      end

      defp broadcast(%unquote(name).State{} = state) do
        GenServer.cast(Farmbot.BotState.Monitor, state)
        state
      end
      defp broadcast(_), do: dispatch {:error, :bad_dispatch}

      defoverridable [load: 1]
    end
  end
end
