defmodule FarmbotOS.Celery.SysCallGlue do
  @moduledoc """
  Behaviour for abstracting CeleryScript functionality.
  """
  alias FarmbotOS.Celery.{AST, RuntimeError}

  @sys_calls Application.compile_env(:farmbot, __MODULE__)[:sys_calls]
  @sys_calls ||
    Mix.raise("""
    config :farmbot, FarmbotOS.Celery.SysCallGlue, [
      sys_calls: SomeModuleThatImplementsTheBehaviour
    ]
    """)

  @type error :: {:error, String.t()}
  @type ok_or_error :: :ok | error

  @type axis :: String.t()
  @type package :: String.t()
  @type resource_id :: integer()

  @callback calibrate(axis) :: ok_or_error
  @callback check_update() :: ok_or_error
  @callback coordinate(x :: number, y :: number, z :: number) ::
              %{x: number(), y: number(), z: number()} | error
  @callback emergency_lock() :: ok_or_error
  @callback emergency_unlock() :: ok_or_error
  @callback execute_script(package, args :: map()) :: ok_or_error
  @callback factory_reset(package :: String.t()) :: ok_or_error
  @callback find_home(axis) :: ok_or_error
  @callback firmware_reboot() :: ok_or_error
  @callback flash_firmware(package) :: ok_or_error
  @callback get_current_x() :: number() | error()
  @callback get_current_y() :: number() | error()
  @callback get_current_z() :: number() | error()

  @callback get_cached_x() :: number() | error()
  @callback get_cached_y() :: number() | error()
  @callback get_cached_z() :: number() | error()

  @callback get_sequence(resource_id) :: FarmbotOS.Celery.AST.t() | error()
  @callback get_toolslot_for_tool(resource_id) ::
              %{x: number(), y: number(), z: number()} | error()
  @callback home(axis, speed :: number()) :: ok_or_error
  @callback move_absolute(
              x :: number(),
              y :: number(),
              z :: number(),
              speed :: number()
            ) ::
              ok_or_error
  @callback move_absolute(
              x :: number(),
              y :: number(),
              z :: number(),
              sx :: number(),
              sy :: number(),
              sz :: number()
            ) :: ok_or_error
  @callback named_pin(named_pin_type :: String.t(), resource_id) ::
              map() | integer | error()
  @callback nothing() :: any()
  @callback point(point_type :: String.t(), resource_id) :: number() | error()
  @callback power_off() :: ok_or_error
  @callback read_pin(pin_num :: number(), pin_mode :: number()) ::
              number | error()
  @callback read_cached_pin(pin_num :: number()) :: number | error()
  @callback toggle_pin(pin_num :: number()) :: ok_or_error
  @callback read_status() :: ok_or_error
  @callback reboot() :: ok_or_error
  @callback send_message(type :: String.t(), message :: String.t(), [atom]) ::
              ok_or_error
  @callback set_servo_angle(pin :: number(), value :: number()) :: ok_or_error
  @callback set_pin_io_mode(pin :: number(), mode :: number()) :: ok_or_error
  @callback set_user_env(env_name :: String.t(), env_value :: String.t()) ::
              ok_or_error
  @callback sync() :: ok_or_error
  @callback wait(millis :: number()) :: ok_or_error
  @callback write_pin(
              pin_num :: number(),
              pin_mode :: number(),
              pin_value :: number
            ) ::
              ok_or_error
  @callback zero(axis) :: ok_or_error

  @callback log(message :: String.t(), force? :: boolean()) :: any()
  @callback sequence_init_log(message :: String.t()) :: any()
  @callback sequence_complete_log(message :: String.t()) :: any()
  @callback perform_lua(
              expression :: String.t(),
              extra_vars :: any(),
              comment :: String.t()
            ) :: ok_or_error
  @callback find_points_via_group(String.t() | resource_id) :: %{
              required(:point_ids) => [resource_id]
            }
  @callback update_resource(kind :: String.t(), resource_id, params :: map()) ::
              ok_or_error
  @callback fbos_config() :: ok_or_error

  def find_points_via_group(sys_calls \\ @sys_calls, point_group_id) do
    point_group_or_error(sys_calls, :find_points_via_group, [point_group_id])
  end

  def format_lhs(sys_calls \\ @sys_calls, lhs)

  def format_lhs(_sys_calls, "x"), do: "current X position"
  def format_lhs(_sys_calls, "y"), do: "current Y position"
  def format_lhs(_sys_calls, "z"), do: "current z position"
  def format_lhs(_sys_calls, "pin" <> num), do: "Pin #{num} value"

  def format_lhs(sys_calls, %{
        kind: :named_pin,
        args: %{pin_type: type, pin_id: pin_id}
      }) do
    case named_pin(sys_calls, type, pin_id) do
      %{label: label} -> label
      {:error, _reason} -> "unknown left hand side"
    end
  end

  def perform_lua(sys_calls \\ @sys_calls, expression, vm_args, comment)
      when is_binary(expression) do
    sys_calls.perform_lua(expression, vm_args, comment)
  end

  def log_assertion(sys_calls \\ @sys_calls, passed?, type, message) do
    if function_exported?(sys_calls, :log_assertion, 3) do
      apply(sys_calls, :log_assertion, [passed?, type, message])
    end
  end

  # TODO: Connor, due to default arg here, things get weird
  def log(message, force? \\ false) when is_binary(message) do
    apply(@sys_calls, :log, [message, force?])
  end

  def sequence_init_log(sys_calls \\ @sys_calls, message)
      when is_binary(message) do
    apply(sys_calls, :sequence_init_log, [message])
  end

  def sequence_complete_log(sys_calls \\ @sys_calls, message)
      when is_binary(message) do
    apply(sys_calls, :sequence_complete_log, [message])
  end

  def calibrate(sys_calls \\ @sys_calls, axis) when axis in ["x", "y", "z"] do
    ok_or_error(sys_calls, :calibrate, [axis])
  end

  def check_update(sys_calls \\ @sys_calls) do
    ok_or_error(sys_calls, :check_update, [])
  end

  def coordinate(sys_calls \\ @sys_calls, x, y, z)
      when is_number(x)
      when is_number(y)
      when is_number(z) do
    coord_or_error(sys_calls, :coordinate, [x, y, z])
  end

  def emergency_lock(sys_calls \\ @sys_calls) do
    ok_or_error(sys_calls, :emergency_lock, [])
  end

  def emergency_unlock(sys_calls \\ @sys_calls) do
    ok_or_error(sys_calls, :emergency_unlock, [])
  end

  def execute_script(sys_calls \\ @sys_calls, package, %{} = env)
      when is_binary(package) do
    ok_or_error(sys_calls, :execute_script, [package, env])
  end

  def factory_reset(sys_calls \\ @sys_calls, package) do
    ok_or_error(sys_calls, :factory_reset, [package])
  end

  def find_home(sys_calls \\ @sys_calls, axis) when axis in ["x", "y", "z"] do
    ok_or_error(sys_calls, :find_home, [axis])
  end

  def firmware_reboot(sys_calls \\ @sys_calls) do
    ok_or_error(sys_calls, :firmware_reboot, [])
  end

  def flash_firmware(sys_calls \\ @sys_calls, package) do
    ok_or_error(sys_calls, :flash_firmware, [package])
  end

  def get_current_x(sys_calls \\ @sys_calls) do
    number_or_error(sys_calls, :get_current_x, [])
  end

  def get_current_y(sys_calls \\ @sys_calls) do
    number_or_error(sys_calls, :get_current_y, [])
  end

  def get_current_z(sys_calls \\ @sys_calls) do
    number_or_error(sys_calls, :get_current_z, [])
  end

  def get_cached_x(sys_calls \\ @sys_calls) do
    number_or_nil_or_error(sys_calls, :get_cached_x, [])
  end

  def get_cached_y(sys_calls \\ @sys_calls) do
    number_or_nil_or_error(sys_calls, :get_cached_y, [])
  end

  def get_cached_z(sys_calls \\ @sys_calls) do
    number_or_nil_or_error(sys_calls, :get_cached_z, [])
  end

  def get_sequence(sys_calls \\ @sys_calls, sequence_id) do
    case sys_calls.get_sequence(sequence_id) do
      %AST{} = ast -> ast
      error -> or_error(sys_calls, :get_sequence, [sequence_id], error)
    end
  end

  def get_toolslot_for_tool(sys_calls \\ @sys_calls, id) do
    coord_or_error(sys_calls, :get_toolslot_for_tool, [id])
  end

  def home(sys_calls \\ @sys_calls, axis, speed)
      when axis in ["x", "y", "z"]
      when is_number(speed) do
    ok_or_error(sys_calls, :home, [axis, speed])
  end

  def move_absolute(sys_calls \\ @sys_calls, x, y, z, speed)
      when is_number(x)
      when is_number(y)
      when is_number(z) do
    ok_or_error(sys_calls, :move_absolute, [x, y, z, speed])
  end

  def move_absolute(
        sys_calls \\ @sys_calls,
        x,
        y,
        z,
        speed_x,
        speed_y,
        speed_z
      )
      when is_number(x)
      when is_number(y)
      when is_number(z) do
    params = [
      x,
      y,
      z,
      speed_x,
      speed_y,
      speed_z
    ]

    ok_or_error(sys_calls, :move_absolute, params)
  end

  def named_pin(sys_calls \\ @sys_calls, type, id) do
    case sys_calls.named_pin(type, id) do
      %{} = data -> %{} = data
      number when is_integer(number) -> number
      error -> or_error(sys_calls, :named_pin, [type, id], error)
    end
  end

  def nothing(sys_calls \\ @sys_calls) do
    sys_calls.nothing()
  end

  def point(sys_calls \\ @sys_calls, type, id) do
    coord_or_error(sys_calls, :point, [type, id])
  end

  def power_off(sys_calls \\ @sys_calls) do
    ok_or_error(sys_calls, :power_off, [])
  end

  def read_pin(sys_calls \\ @sys_calls, pin_num, pin_mode) do
    number_or_error(sys_calls, :read_pin, [pin_num, pin_mode])
  end

  def read_cached_pin(sys_calls \\ @sys_calls, pin_num) do
    number_or_nil_or_error(sys_calls, :read_cached_pin, [pin_num])
  end

  def toggle_pin(sys_calls \\ @sys_calls, pin_num) do
    ok_or_error(sys_calls, :toggle_pin, [pin_num])
  end

  def read_status(sys_calls \\ @sys_calls) do
    fs = FarmbotOS.BotState.FileSystem
    if Process.whereis(fs), do: send(fs, :timeout)
    ok_or_error(sys_calls, :read_status, [])
  end

  def reboot(sys_calls \\ @sys_calls) do
    ok_or_error(sys_calls, :reboot, [])
  end

  def send_message(sys_calls \\ @sys_calls, kind, msg, channels) do
    ok_or_error(sys_calls, :send_message, [kind, msg, channels])
  end

  def set_servo_angle(sys_calls \\ @sys_calls, pin_num, pin_value) do
    ok_or_error(sys_calls, :set_servo_angle, [pin_num, pin_value])
  end

  def set_pin_io_mode(sys_calls \\ @sys_calls, pin_number, pin_io_mode) do
    ok_or_error(sys_calls, :set_pin_io_mode, [pin_number, pin_io_mode])
  end

  def set_user_env(sys_calls \\ @sys_calls, key, value) do
    ok_or_error(sys_calls, :set_user_env, [key, value])
  end

  def sync(sys_calls \\ @sys_calls) do
    ok_or_error(sys_calls, :sync, [])
  end

  def wait(sys_calls \\ @sys_calls, millis) do
    ok_or_error(sys_calls, :wait, [millis])
  end

  def write_pin(sys_calls \\ @sys_calls, pin_number, pin_mode, pin_value) do
    ok_or_error(sys_calls, :write_pin, [pin_number, pin_mode, pin_value])
  end

  def zero(sys_calls \\ @sys_calls, axis) when axis in ["x", "y", "z"] do
    ok_or_error(sys_calls, :zero, [axis])
  end

  def update_resource(sys_calls \\ @sys_calls, kind, id, params) do
    ok_or_error(sys_calls, :update_resource, [kind, id, params])
  end

  def fbos_config(sys_calls \\ @sys_calls) do
    case apply(sys_calls, :fbos_config, []) do
      {:ok, conf} -> {:ok, conf}
      error -> or_error(sys_calls, :fbos_config, [], error)
    end
  end

  defp ok_or_error(sys_calls, fun, args) do
    case apply(sys_calls, fun, args) do
      :ok -> :ok
      error -> or_error(sys_calls, fun, args, error)
    end
  end

  defp number_or_error(sys_calls, fun, args) do
    case apply(sys_calls, fun, args) do
      result when is_number(result) -> result
      error -> or_error(sys_calls, fun, args, error)
    end
  end

  defp number_or_nil_or_error(sys_calls, fun, args) do
    case apply(sys_calls, fun, args) do
      result when is_number(result) -> result
      nil -> nil
      error -> or_error(sys_calls, fun, args, error)
    end
  end

  defp coord_or_error(sys_calls, fun, args) do
    case apply(sys_calls, fun, args) do
      %{x: x, y: y, z: z} = coord
      when is_number(x)
      when is_number(y)
      when is_number(z) ->
        coord

      error ->
        or_error(sys_calls, fun, args, error)
    end
  end

  defp point_group_or_error(sys_calls, fun, args) do
    case apply(sys_calls, fun, args) do
      %{point_ids: ids} = point_group when is_list(ids) -> point_group
      error -> or_error(sys_calls, fun, args, error)
    end
  end

  defp or_error(_sys_calls, _fun, _args, {:error, reason})
       when is_binary(reason) do
    {:error, reason}
  end

  defp or_error(sys_calls, fun, args, bad_val) do
    raise RuntimeError,
      message: """
      Bad return value: #{inspect(bad_val)}
      called as:
        #{sys_calls}.#{fun}(#{Enum.join(Enum.map(args, &inspect/1), ",")})
      """
  end
end
