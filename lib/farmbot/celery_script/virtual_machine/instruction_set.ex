defmodule Farmbot.CeleryScript.VirtualMachine.InstructionSet do
  @moduledoc "Map of CeleryScript `kind` to implementation module."
  alias Farmbot.CeleryScript.VirtualMachine.Instruction.{
          Execute,
          WritePin,
          Nothing,
          InstallFarmware,
          Calibrate,
          SetUserEnv,
          MoveRelative,
          RpcOk,
          EmergencyUnlock,
          MoveAbsolute,
          ReadAllParams,
          ReadParam,
          InstallFirstPartyFarmware,
          If,
          Reboot,
          RpcRequest,
          Wait,
          EmergencyLock,
          TogglePin,
          Zero,
          ConfigUpdate,
          RemoveFarmware,
          ExecuteScript,
          Sync,
          TakePhoto,
          RpcError,
          Coordinate,
          Pair,
          Home,
          UpdateFarmware,
          Sequence,
          PowerOff,
          DataUpdate,
          FactoryReset,
          SendMessage,
          Explanation,
          FindHome,
          ReadStatus,
          CheckUpdates,
          ReadPin
        }

  defstruct _if: If,
            calibrate: Calibrate,
            check_updates: CheckUpdates,
            config_update: ConfigUpdate,
            coordinate: Coordinate,
            data_update: DataUpdate,
            emergency_lock: EmergencyLock,
            emergency_unlock: EmergencyUnlock,
            execute: Execute,
            execute_script: ExecuteScript,
            explanation: Explanation,
            factory_reset: FactoryReset,
            find_home: FindHome,
            home: Home,
            install_farmware: InstallFarmware,
            install_first_party_farmware: InstallFirstPartyFarmware,
            move_absolute: MoveAbsolute,
            move_relative: MoveRelative,
            nothing: Nothing,
            pair: Pair,
            power_off: PowerOff,
            read_all_params: ReadAllParams,
            read_param: ReadParam,
            read_pin: ReadPin,
            read_status: ReadStatus,
            reboot: Reboot,
            remove_farmware: RemoveFarmware,
            rpc_error: RPCError,
            rpc_ok: RPCOk,
            rpc_request: RPCRequest,
            send_message: SendMessage,
            sequence: Sequence,
            set_user_env: SetUserEnv,
            sync: Sync,
            take_photo: TakePhoto,
            toggle_pin: TogglePin,
            update_farmware: UpdateFarmware,
            wait: Wait,
            write_pin: WritePin,
            zero: Zero

  def fetch(instrs, instr) when is_binary(instr) do
    valid_keys = Enum.map(Map.keys(instrs), &Atom.to_string(&1))

    if instr in valid_keys do
      Map.fetch(instrs, :"#{instr}")
    else
      :error
    end
  end

  def fetch(instrs, instr) do
    case Map.get(instrs, instr) do
      nil -> :error
      mod -> {:ok, mod}
    end
  end
end
