defmodule Farmbot.BotState.Configuration do
  defmodule State do
    @type t :: %__MODULE__{
      locks: list(String.t),
      configuration: %{
        os_auto_update: boolean,
        fw_auto_update: boolean,
        timezone:       String.t | nil,
        steps_per_mm:   integer
      },
      informational_settings: %{
        controller_version: String.t,
        private_ip: nil | String.t,
        throttled: String.t,
        target: String.t,
        compat_version: integer,
        environment: :prod | :dev | :test
      }
    }
    defstruct [
      locks: [],
      configuration: %{
        os_auto_update: false,
        fw_auto_update: false,
        timezone:       nil,
        steps_per_mm:   500
      },
      informational_settings: %{
        controller_version: "loading...",
        compat_version: -1,
        target: "loading...",
        environment: :loading,
        private_ip: nil,
        throttled: "loading..."
       },
    ]

    @spec broadcast(t) :: t
    def broadcast(%State{} = state) do
      GenServer.cast(Farmbot.BotState.Monitor, state)
      state
    end
  end

  use GenServer
  require Logger
  def init(%{compat_version: compat_version,
             env:            env,
             target:         target,
             version:        version})
  do
    initial_state = %State{
      informational_settings: %{
        controller_version: version,
        compat_version:     compat_version,
        target:             target,
        environment:        env,
        throttled:          get_throttled
      }}
      IO.inspect initial_state
    {:ok, State.broadcast(initial_state)}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # This call should probably be a cast actually, and im sorry.
  # Returns true for configs that exist and are the correct typpe,
  # and false for anything else
  # TODO make sure these are properly typed.
  def handle_call({:update_config, "os_auto_update", value}, _from, %State{} = state)
  when is_boolean(value) do
    new_config = Map.put(state.configuration, :os_auto_update, value)
    dispatch true, %State{state | configuration: new_config}
  end

  def handle_call({:update_config, "fw_auto_update", value}, _from, %State{} = state)
  when is_boolean(value) do
    new_config = Map.put(state.configuration, :fw_auto_update, value)
    dispatch true, %State{state | configuration: new_config}
  end

  def handle_call({:update_config, "timezone", value}, _from, %State{} = state)
  when is_bitstring(value) do
    new_config = Map.put(state.configuration, :timezone, value)
    dispatch true, %State{state | configuration: new_config}
  end

  def handle_call({:update_config, "steps_per_mm", value}, _from, %State{} = state)
  when is_integer(value) do
    new_config = Map.put(state.configuration, :steps_per_mm, value)
    dispatch true, %State{state | configuration: new_config}
  end

  def handle_call({:update_config, key, _value}, _from, %State{} = state) do
    Logger.error("#{key} is not a valid config.")
    dispatch false, state
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CALL!: #{inspect event}", [__MODULE__])
    dispatch :unhandled, state
  end

  def handle_cast(event, %State{} = state) do
    Logger.warn("[#{__MODULE__}] UNHANDLED CAST!: #{inspect event}", [__MODULE__])
    dispatch state
  end

  defp dispatch(reply, %State{} = state) do
    State.broadcast(state)
    {:reply, reply, state}
  end

  defp dispatch(%State{} = state) do
    State.broadcast(state)
    {:noreply, state}
  end

  def get_throttled do
      {output, 0} = System.cmd("vcgencmd", ["get_throttled"])
      {"throttled=0x0\n", 0}
      [_, throttled] = output
      |> String.strip
      |> String.split("=")
      throttled
  end
end
