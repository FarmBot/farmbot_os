defmodule Farmbot.Repo.SeedDB do
  @moduledoc "Initial seeds of the database for factory defaults."
  use GenServer
  alias Farmbot.System.ConfigStorage
  @builtins Application.get_env(:farmbot, :builtins)

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    sequence(builtin(:sequence, :emergency_lock), "emergency_lock")
    sequence(builtin(:sequence, :emergency_unlock), "emergency_unlock")
    sequence(builtin(:sequence, :sync), "sync")
    sequence(builtin(:sequence, :reboot), "reboot")
    sequence(builtin(:sequence, :power_off), "power_off")

    pin_binding(builtin(:pin_binding, :emergency_lock), builtin(:sequence, :emergency_lock), 17)
    pin_binding(builtin(:pin_binding, :emergency_unlock), builtin(:sequence, :emergency_unlock), 23)

    :ignore
  end

  def sequence(id, kind, args \\ %{}, body \\ []) do
    ConfigStorage.register_sync_cmd(id, "Sequence", %{id: id, name: "__#{kind}", kind: kind, args: args, body: body})
    |> Farmbot.Repo.apply_sync_cmd()
  end

  def pin_binding(id, sequence_id, pin_num) do
    ConfigStorage.register_sync_cmd(id, "PinBinding", %{id: id, sequence_id: sequence_id, pin_num: pin_num})
    |> Farmbot.Repo.apply_sync_cmd()
  end

  def builtin(kind, label) do
    @builtins[kind][label] || raise("no #{kind} builtin by label: #{label}")
  end
end
