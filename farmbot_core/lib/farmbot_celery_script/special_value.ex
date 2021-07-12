defmodule FarmbotCeleryScript.SpecialValue do
  alias FarmbotCore.Asset.{ Repo, Point }
  alias FarmbotCeleryScript.Interpolation
  require Logger
  require FarmbotCore.Logger
  import Ecto.Query
  @msg "Need at least 3 soil height samples to guess soil height. "
    <> "Using fallback value instead: "
  def safe_height() do
    FarmbotCore.Asset.fbos_config(:safe_height) || 0.0
  end

  def soil_height(%{x: _, y: _} = xy) do
    points = soil_samples()
    count  = Enum.count(points)
    if count < 3 do
      fallback = FarmbotCore.Asset.fbos_config(:soil_height) || 0.0
      FarmbotCore.Logger.error(3, @msg <> inspect(fallback))
      fallback
    else
      Interpolation.guess_z_value(points, xy)
    end
  end

  defp soil_samples do
    Repo.all(from(p in Point, where: like(p.meta, "%at_soil_level%")))
    |> Enum.filter(&is_soil_sample?/1)
  end

  defp is_soil_sample?(%{meta: %{"at_soil_level" => "true"}}), do: true
  defp is_soil_sample?(_), do: false
end
