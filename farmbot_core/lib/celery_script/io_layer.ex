defmodule Farmbot.CeleryScript.IOLayer do
  alias Csvm.AST
  @type args :: AST.args()
  @type body :: AST.body()

  # Simple IO
  @callback write_pin(args, body) :: :ok | {:error, String.t}
  @callback read_pin(args, body) :: :ok | {:error, String.t}
  @callback set_servo_angle(args, body) :: :ok | {:error, String.t}
  @callback send_message(args, body) :: :ok | {:error, String.t}
  @callback move_relative(args, body) :: :ok | {:error, String.t}
  @callback home(args, body) :: :ok | {:error, String.t}
  @callback find_home(args, body) :: :ok | {:error, String.t}
  @callback wait(args, body) :: :ok | {:error, String.t}
  @callback toggle_pin(args, body) :: :ok | {:error, String.t}
  @callback execute_script(args, body) :: :ok | {:error, String.t}
  @callback zero(args, body) :: :ok | {:error, String.t}
  @callback calibrate(args, body) :: :ok | {:error, String.t}
  @callback take_photo(args, body) :: :ok | {:error, String.t}
  @callback config_update(args, body) :: :ok | {:error, String.t}
  @callback set_user_env(args, body) :: :ok | {:error, String.t}
  @callback install_first_party_farmware(args, body) :: :ok | {:error, String.t}
  @callback install_farmware(args, body) :: :ok | {:error, String.t}
  @callback uninstall_farmware(args, body) :: :ok | {:error, String.t}
  @callback update_farmware(args, body) :: :ok | {:error, String.t}
  @callback read_status(args, body) :: :ok | {:error, String.t}
  @callback sync(args, body) :: :ok | {:error, String.t}
  @callback power_off(args, body) :: :ok | {:error, String.t}
  @callback reboot(args, body) :: :ok | {:error, String.t}
  @callback factory_reset(args, body) :: :ok | {:error, String.t}
  @callback change_ownership(args, body) :: :ok | {:error, String.t}
  @callback check_updates(args, body) :: :ok | {:error, String.t}
  @callback dump_info(args, body) :: :ok | {:error, String.t}
  @callback move_absolute(args, body) :: :ok | {:error, String.t}

  # Complex IO.
  # @callbcak _if(args, body) :: {:ok, AST.t} | {:error, String.t}
  @callback execute(args, body) :: {:ok, AST.t} | {:error, String.t}

  # Special IO.
  @callback emergency_lock(args, body) :: any
  @callback emergency_unlock(args, body) :: any
end
