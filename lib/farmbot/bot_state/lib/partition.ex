defmodule Farmbot.BotState.Lib.Partition do
  @moduledoc "Common functionality for parts of the bot state."
  alias Farmbot.BotState

  defmodule PrivateState do
    @moduledoc "Internal state to a Partition."

    @enforce_keys [:bot_state_tracker, :public]
    defstruct [:bot_state_tracker, :public]

    @typedoc "Public state."
    @type public :: map

    @typedoc "Private State."
    @type t :: %__MODULE__{
      bot_state_tracker: Farmbot.BotState.state_server,
      public: public
    }
  end

  @typedoc "Reply to a GenServer.call."
  @type reply :: {:reply, term, PrivateState.public}

  @typedoc "Noreply for GenServer.cast or GenServer.info."
  @type noreply :: {:noreply, PrivateState.public}

  @typedoc "Stop the Partition."
  @type stop :: {:stop, term, PrivateState.public} | {:stop, term}

  @doc "Start this Partition GenServer."
  @callback start_link(BotState.server, GenServer.options) :: GenServer.on_start

  @doc "optional callback called on init."
  @callback partition_init(PrivateState.t) :: {:ok, PrivateState.t} | {:stop, term}

  @doc "Optional callback for handle_call."
  @callback partition_call(term, GenServer.from, PrivateState.public) :: reply | noreply | stop

  @doc "Optional callback for handle_cast."
  @callback partition_cast(term, PrivateState.public) :: noreply | stop

  @doc "Optional callback for handle_info."
  @callback partition_info(term, PrivateState.public) :: noreply | stop

  @doc "Otional callback for saveing state."
  @callback save_state(PrivateState.public) :: :ok | :error

  @optional_callbacks [
    partition_init: 1,
    partition_call: 3,
    partition_info: 2,
    partition_cast: 2,
    save_state: 1
  ]

  @doc "Dispatches to the bot state tracker."
  @spec dispatch(PrivateState.t) :: {:noreply, PrivateState.t}
  def dispatch(private_state)
  def dispatch(%PrivateState{} = priv) do
    GenServer.cast(priv.bot_state_tracker, {:update, priv.public.__struct__, priv.public})
    {:noreply, priv}
  end

  @doc "Dispatches to the bot state tracker, and replies with `reply`"
  @spec dispatch(term, PrivateState.t) :: {:reply, term, PrivateState.t}
  def dispatch(reply, private_state)
  def dispatch(reply, %PrivateState{} = priv) do
    GenServer.cast(priv.bot_state_tracker, {:update, priv.public.__struct__, priv.public})
    {:reply, reply, priv}
  end

  @doc false
  defmacro __using__(_opts) do
    quote do

      alias Farmbot.BotState.Lib.Partition
      import Partition
      @behaviour Partition

      alias Partition.PrivateState

      use GenServer
      require Logger

      @doc "Start the partition."
      def start_link(bot_state_tracker, opts) do
        GenServer.start_link(__MODULE__, bot_state_tracker, opts)
      end

      def init(bot_state_tracker) do
        initial = %PrivateState{public: struct(__MODULE__),
                                bot_state_tracker: bot_state_tracker}
        partition_init(initial)
      end

      def handle_call(call, from, %PrivateState{} = priv) do
        case partition_call(call, from, priv.public) do
          {:reply, reply, pub} -> dispatch reply, %{priv | public: pub}
          {:noreply, pub} ->
            save_public_data(pub)
            dispatch %{priv | public: pub}
          other -> other
        end
      end

      def handle_cast(cast, %PrivateState{} = priv) do
        case partition_cast(cast, priv.public) do
          {:noreply, pub} ->
            save_public_data(pub)
            dispatch %{priv | public: pub}
          other -> other
        end
      end

      def handle_info(info, %PrivateState{} = priv) do
        case partition_info(info, priv.public) do
          {:noreply, pub} ->
            save_public_data(pub)
            dispatch %{priv | public: pub}
          other -> other
        end
      end

      @doc false
      def partition_init(%PrivateState{} = priv), do: {:ok, priv}

      @doc false
      def partition_call(call, _from, public) do
        Logger.error "Unhandled call: #{inspect call}"
        {:stop, {:unhandled_call, call}, public}
      end

      @doc false
      def partition_cast(cast, public) do
        Logger.warn "Unhandled cast: #{inspect cast}"
        {:noreply, public}
      end

      @doc false
      def partition_info(info, public) do
        Logger.warn "Unhandled info: #{inspect info}"
        {:noreply, public}
      end

      defp save_public_data(pub) do
        if function_exported?(__MODULE__, :save_state, 1) do
          :ok = apply(__MODULE__, :save_state, [pub])
        else
          :ok
        end
      end

      defoverridable [partition_init: 1,
                      partition_call: 3,
                      partition_cast: 2,
                      partition_info: 2,
                      ]
    end
  end
end
