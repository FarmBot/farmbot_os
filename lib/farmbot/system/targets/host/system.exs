defmodule Module.concat([Farmbot,System,"host"]) do 
  @moduledoc false
  @behaviour Farmbot.System

  require IEx

  def reboot, do: :ok
  def power_off, do: :ok

  def factory_reset(reason) do
    files = path() |> File.ls!()
    Farmbot.System.FS.transaction fn() ->
      File.rm_rf files
      File.write("#{path()}/factory_reset_reason", reason)
    end, true
    IEx.pry
    System.halt(0)
  end

  defp path, do: Farmbot.System.FS.path()
end
