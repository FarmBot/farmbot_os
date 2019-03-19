defmodule FarmbotCeleryScript.SysCalls do
  @moduledoc """
  Behaviour for abstracting CeleryScript functionality.
  """
  alias FarmbotCeleryScript.{AST, RuntimeError}

  @sys_call_implementation Application.get_env(:farmbot_celery_script, __MODULE__)[:sys_calls]
  @sys_call_implementation ||
    Mix.raise("""
    config :farmbot_celery_script, FarmbotCeleryScript.SysCalls, [
      sys_calls: SomeModuleThatImplementsTheBehaviour
    ]
    """)

  @type error :: {:error, String.t()}

  @type resource_id :: integer()

  @type point_type :: String.t()
  @type named_pin_type :: String.t()

  @type axis_position :: float()
  @type axis :: String.t()
  @type axis_speed :: integer()
  @type coordinate :: %{x: axis_position, y: axis_position, z: axis_position}

  @type(pin_number :: {:boxled, 3 | 4}, integer)
  @type pin_mode :: 0 | 1 | nil
  @type pin_value :: integer

  @type milliseconds :: integer

  @type message_level :: String.t()
  @type message_channel :: String.t()
  @type package :: String.t()

  @callback point(point_type, resource_id) :: coordinate | error
  @callback move_absolute(x :: axis_position, y :: axis_position, z :: axis_position, axis_speed) ::
              :ok | error
  @callback find_home(axis, axis_speed) :: :ok | error

  @callback calibrate(axis) :: :ok | error

  @callback get_current_x() :: axis_position | error
  @callback get_current_y() :: axis_position | error
  @callback get_current_z() :: axis_position | error

  @callback write_pin(pin_number, pin_mode, pin_value) :: :ok | error
  @callback read_pin(pin_number, pin_mode) :: :ok | error
  @callback named_pin(named_pin_type, resource_id) :: pin_number | error

  @callback wait(milliseconds) :: any()

  @callback send_message(message_level, String.t(), [message_channel]) :: :ok | error

  @callback get_sequence(resource_id) :: map() | error
  @callback execute_script(String.t(), map()) :: :ok | error

  @callback read_status() :: map()

  @callback set_user_env(String.t(), String.t()) :: :ok | error

  @callback sync() :: :ok | error

  @callback flash_firmware(package) :: :ok | error

  def flash_firmware(module \\ @sys_call_implementation, package) do
    case module.flash_firmware(package) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def point(module \\ @sys_call_implementation, type, id) do
    case module.point(type, id) do
      %{x: x, y: y, z: z} -> coordinate(x, y, z)
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def move_absolute(module \\ @sys_call_implementation, x, y, z, speed) do
    case module.move_absolute(x, y, z, speed) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def calibrate(module \\ @sys_call_implementation, axis) do
    case module.calibrate(axis) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def get_current_x(module \\ @sys_call_implementation) do
    case module.get_current_x() do
      position when is_number(position) -> position
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def get_current_y(module \\ @sys_call_implementation) do
    case module.get_current_y() do
      position when is_number(position) -> position
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def get_current_z(module \\ @sys_call_implementation) do
    case module.get_current_z() do
      position when is_number(position) -> position
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def write_pin(module \\ @sys_call_implementation, pin_number, pin_mode, pin_value) do
    case module.write_pin(pin_number, pin_mode, pin_value) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def read_pin(module \\ @sys_call_implementation, pin_number, pin_mode) do
    case module.read_pin(pin_number, pin_mode) do
      value when is_number(value) -> value
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def named_pin(module \\ @sys_call_implementation, type, id) do
    case module.named_pin(type, id) do
      {:boxled, boxledid} when boxledid in [3, 4] -> {:boxled, boxledid}
      number when is_integer(number) -> number
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def wait(module \\ @sys_call_implementation, milliseconds) do
    _ = module.wait(milliseconds)
    :ok
  end

  def send_message(module \\ @sys_call_implementation, level, message, channels) do
    case module.send_message(level, message, channels) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def find_home(module \\ @sys_call_implementation, axis, speed) do
    case module.find_home(axis, speed) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def get_sequence(module \\ @sys_call_implementation, id) do
    case module.get_sequence(id) do
      %{kind: _, args: _} = probably_sequence ->
        AST.decode(probably_sequence)

      {:error, reason} when is_binary(reason) ->
        error(reason)
    end
  end

  def execute_script(module \\ @sys_call_implementation, name, args) do
    case module.execute_script(name, args) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def read_status(module \\ @sys_call_implementation) do
    _ = module.read_status
  end

  def set_user_env(module \\ @sys_call_implementation, key, val) do
    case module.set_user_env(key, val) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def sync(module \\ @sys_call_implementation) do
    case module.sync() do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> error(reason)
    end
  end

  def nothing, do: nil

  def coordinate(x, y, z) do
    %{x: x, y: y, z: z}
  end

  def error(message) when is_binary(message) do
    raise RuntimeError, message: message
  end
end
