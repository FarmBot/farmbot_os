defmodule Farmbot.Repo.SeedDB do
  @moduledoc "Initial seeds of the database for factory defaults."
  use GenServer
  alias Farmbot.System.ConfigStorage
  @builtins Application.get_env(:farmbot, :builtins)

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    run()
    :ignore
  end

  def run do
    pin_binding(builtin(:pin_binding, :emergency_lock), "emergency_lock", 17)
    pin_binding(builtin(:pin_binding, :emergency_unlock), "emergency_unlock", 23)
  end

  def pin_binding(id, special_action, pin_num) do
    body = %{
      id: id,
      sequence_id: nil,
      special_action: special_action,
      pin_num: pin_num
    }
    ConfigStorage.register_sync_cmd(id, "PinBinding", body)
    |> Farmbot.Repo.apply_sync_cmd()
  end

  def builtin(kind, label) do
    @builtins[kind][label] || raise("no #{kind} builtin by label: #{label}")
  end
end
