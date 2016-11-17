alias Farmbot.BotState.Hardware,      as: Hardware
alias Farmbot.BotState.Configuration, as: Configuration
alias Farmbot.BotState.Authorization, as: Authorization
alias Serialized, as: State # DELETE ME

defmodule Farmbot.BotState do
  require Logger
  @moduledoc """
    Functions to modifying Farmbot's state
  """

  def init(args) do
    NetMan.put_pid(Farmbot.BotState)
    {:ok, load(args)}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def save(state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
    state
  end



  def load(%{target: target, compat_version: compat_version, env: env, version: version}) do
    token = case  Farmbot.Auth.get_token() do
      {:ok, token} -> token
      _ -> nil
    end
    default_state = %State{
      configuration: %{
        os_auto_update: false,
        fw_auto_update: false,
        timezone:       nil,
        steps_per_mm:   500
      },
      informational_settings: %{
        controller_version: version,
        private_ip: nil,
        throttled: :blah, #get_throttled,
        target: target,
        compat_version: compat_version,
        environment: env
      }
    }
    case SafeStorage.read(__MODULE__) do
      { :ok, rcontents } ->
        l = Map.keys(default_state)
        r = Map.keys(rcontents)
        Logger.debug("default: #{inspect l} saved: #{inspect r}")
        if(l != r) do # SORRY ABOUT THIS
          Logger.warn("UPDATING TO NEW STATE TREE FORMAT OR SOMETHING")
          spawn fn -> apply_auth(default_state.authorization) end
          spawn fn -> apply_status(default_state) end
          default_state
        else
          Logger.debug("Trying to apply last bot state")
          spawn fn -> apply_auth(rcontents.authorization) end
          spawn fn -> apply_status(rcontents) end
          old_config = rcontents.configuration
          old_auth = rcontents.authorization
          old_sch = rcontents.farm_scheduler
          Map.put(default_state, :configuration, old_config)
          |> Map.put(:authorization, old_auth)
        end
      _ ->
          spawn fn -> apply_auth(default_state.authorization) end
          spawn fn -> apply_status(default_state) end
          default_state
    end
  end

  @doc """
    Gets the current position of the bot. Returns [x,y,z]
  """
  @spec get_current_pos() :: [integer, ...]
  def get_current_pos do
    GenServer.call(Hardware, :get_current_pos)
  end

  @doc """
    Sets the position to givin position.
  """
  @spec set_pos(integer,integer,integer) :: :ok
  def set_pos(x, y, z)
  when is_integer(x) and is_integer(y) and is_integer(z) do
    GenServer.cast(Hardware, {:set_pos, {x, y, z}})
  end

  @doc """
    Sets a pin under the given value
  """
  @spec set_pin_value(integer, integer) :: :ok
  def set_pin_value(pin, value) when is_integer(pin) and is_integer(value) do
    GenServer.cast(Hardware, {:set_pin_value, {pin, value}})
  end

  @doc """
    Sets a mode for a particular pin.
    This should happen before setting the value if possible.
  """
  @spec set_pin_mode(integer,0 | 1) :: :ok
  def set_pin_mode(pin, mode)
  when is_integer(pin) and is_integer(mode) do
    GenServer.cast(Hardware, {:set_pin_mode, {pin, mode}})
  end

  @doc """
    Sets a param to a particular value.
    This should be the human readable atom version of the param.
  """
  @spec set_param(atom, integer) :: :ok
  def set_param(param, value) when is_atom(param) do
    GenServer.cast(Hardware, {:set_param, {param, value}})
  end

  @doc """
    Gets the map of every param.
    Useful for resetting params if the arduino flops
  """
  @spec get_all_mcu_params :: Hardware.State.mcu_params
  def get_all_mcu_params do
    GenServer.call(Hardware, :get_all_mcu_params)
  end

  @doc """
    gets the value of a pin.
  """
  @spec get_pin(integer) :: %{mode: 0 | 1,   value: number}
  def get_pin(pin_number) when is_integer(pin_number) do
    GenServer.call(Hardware, {:get_pin, pin_number})
  end

  @doc """
    Gets the most recent token
  """
  @spec get_token() :: map
  def get_token do
    GenServer.call(Authorization, :get_token)
  end

  @doc """
    Adds credentials.
    TODO: FIX THIS DONT STORE PASS IN PLAIN TEXT YOU NOOB
  """
  @spec add_creds({String.t, String.t, String.t}) :: :ok
  def add_creds({email, pass, server}) do
    GenServer.cast(Authorization, {:creds, {email, pass, server}})
  end

  @doc """
    Gets the current controller version
  """
  @spec get_version :: String.t
  def get_version do
    GenServer.call(Configuration, :get_version)
  end

  @doc """
    Update a config under key
  """
  @spec update_config(String.t, any) :: :ok | {:error, atom}
  def update_config(config_key, value)
  when is_bitstring(config_key) do
    GenServer.call(Configuration, {:update_config, config_key, value})
  end

  @doc """
    Gets the value stored under key.
  """
  @spec get_config(atom) :: nil | any
  def get_config(config_key) when is_atom(config_key) do
    GenServer.call(Configuration, {:get_config, config_key})
  end

  @spec get_lock(String.t) :: integer | nil
  def get_lock(string) when is_bitstring(string) do
    GenServer.call(Configuration, {:get_lock, string})
  end

  @spec add_lock(String.t) :: :ok
  def add_lock(string) when is_bitstring(string) do
    GenServer.cast(Configuration, {:add_lock, string})
  end

  @spec remove_lock(String.t) :: :ok | {:error, atom}
  def remove_lock(string) when is_bitstring(string) do
    GenServer.call(Configuration, {:remove_lock, string})
  end

  def set_end_stop(_something) do
    #TODO
    nil
  end

  def apply_status(state) do
    p = Process.whereis(Farmbot.Serial.Gcode.Handler)
    if(is_pid(p) == true and Process.alive?(p) == true) do
      Process.sleep(500) # I don't remember why i did this.
      Command.home_all(100)
      apply_params(state.mcu_params)
    else
      Process.sleep(10)
      apply_status(state)
    end
    state
  end

  def apply_auth(%{
    token: _,
    email: email,
    pass: pass,
    server: server,
    network: network
  })
  do
    add_creds({email, pass, server})
    NetMan.connect(network, Farmbot.BotState)
  end

  # params will be a list of atoms here.
  def apply_params(params) when is_map(params) do
    case Enum.partition(params, fn({param, value}) ->
      ## We need the integer version of said param
      param_int = Farmbot.Serial.Gcode.Parser.parse_param(param)
      spawn fn -> Command.update_param(param_int, value) end
    end)
    do
      {[], []} -> Logger.debug("Fresh mcu params state")
                  Command.read_all_params
      {_, []} -> Logger.debug("Params are set!")
      {_, errors} -> Logger.error("Error resetting params: #{inspect errors}")
    end
  end

  def apply_params(params) do
    Logger.error("Something weird happened applying last params: #{inspect params}")
  end

  def set_time do
    System.cmd("ntpd", ["-q",
     "-p", "0.pool.ntp.org",
     "-p", "1.pool.ntp.org",
     "-p", "2.pool.ntp.org",
     "-p", "3.pool.ntp.org"])
    check_time_set
    Logger.debug("Time set.")
    :ok
  end

  def check_time_set do
    if :os.system_time(:seconds) <  1474929 do
      check_time_set # wait until time is set
    end
  end


# THESE NEED TO GO AWAY




def handle_call({:get_config, key}, _from, state)
when is_atom(key) do
  {:reply, Map.get(state.configuration, key), state}
end

def handle_call(:get_token, _from, state) do
  {:reply, state.authorization.token, state}
end

# Allow the frontend to do stuff again.
def handle_call({:remove_lock, string}, _from,  state) do
  maybe_index = Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
  cond do
    is_integer(maybe_index) ->
      {:reply, :ok, Map.put(state, :locks,
        List.delete_at(state.locks, maybe_index))}
    true ->
      {:reply, {:error, :no_index}, state}
  end
end

def handle_call({:get_lock, string}, _from, state) do
  maybe_index = Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
  {:reply, maybe_index, state}
end

# Lock the frontend from doing stuff
def handle_cast({:add_lock, string}, state) do
  maybe_index = Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
  cond do
    is_integer(maybe_index) ->
      {:noreply, Map.put(state, :locks,
        List.replace_at(state.locks, maybe_index, %{reason: string}) )}
    is_nil(maybe_index) ->
      {:noreply, Map.put(state, :locks,
        state.locks ++ [%{reason: string}] )}
  end
end

def handle_cast({:update_info, key, value}, state) do
  new_info = Map.put(state.informational_settings, key, value)
  {:noreply, Map.put(state, :informational_settings, new_info)}
end



def handle_info({:connected, network, ip_addr}, state) do
  # GenServer.cast(Farmbot.BotState, {:update_info, :private_ip, address})
  new_info = Map.put(state.informational_settings, :private_ip, ip_addr)
  email = state.authorization.email
  pass = state.authorization.pass
  server = state.authorization.server

  case Farmbot.Auth.login(email, pass, server) do
    {:ok, token} ->
      Logger.debug("Got Token!")
      auth = Map.merge(state.authorization,
              %{email: email, pass: pass, server: server, token: token,
                network: network})
      set_time
      Farmbot.node_reset(ip_addr)
      {:noreply,
        Map.put(state, :authorization, auth)
        |> Map.put(:informational_settings, new_info)
      }
    # If the bot is faster than your router (often) this can happen.
    {:error, "enetunreach"} ->
      Logger.warn("Something super weird happened.. Probably a race condition.")
      # Just crash ourselves and try again.
      handle_info({:connected, network, ip_addr}, state)
    error ->
      Logger.error("Something bad happened when logging in!: #{inspect error}")
      Farmbot.factory_reset
      {:noreply, state}
    end
end
end
