defmodule Farmbot.Asset.Repo do
  @moduledoc "Repo for storing Asset data."
  require Farmbot.Logger
  alias Farmbot.Asset.Repo.Snapshot
  use Ecto.Repo,
    otp_app: :farmbot_core,
    adapter: Application.get_env(:farmbot_core, __MODULE__)[:adapter]

  alias Farmbot.Asset.{
    Device,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool,
  }

  def snapshot do
    results = Farmbot.Asset.Repo.all(Device) ++
      Farmbot.Asset.Repo.all(FarmEvent) ++
      Farmbot.Asset.Repo.all(FarmwareEnv) ++
      Farmbot.Asset.Repo.all(FarmwareInstallation) ++
      Farmbot.Asset.Repo.all(Peripheral) ++
      Farmbot.Asset.Repo.all(PinBinding) ++
      Farmbot.Asset.Repo.all(Point) ++
      Farmbot.Asset.Repo.all(Regimen) ++
      Farmbot.Asset.Repo.all(Sensor) ++
      Farmbot.Asset.Repo.all(Sequence) ++
      Farmbot.Asset.Repo.all(Tool)

    %Snapshot{data: results}
    |> Snapshot.md5()
  end
end
