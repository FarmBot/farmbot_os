defmodule FarmbotOS.Celery.SpecialValue do
  alias FarmbotOS.Celery.Interpolation
  alias FarmbotOS.Asset.{Repo, Point}
  import Ecto.Query
  require FarmbotOS.Logger
  require Logger

  @msg "Need at least 3 soil height samples to guess soil height. " <>
         "Using fallback value instead: "
  def safe_height() do
    FarmbotOS.Asset.fbos_config(:safe_height) || 0.0
  end

  def soil_height(%{x: _, y: _} = xy) do
    points = soil_samples()

    if Enum.count(points) < 3 do
      fallback = FarmbotOS.Asset.fbos_config(:soil_height) || 0.0
      FarmbotOS.Logger.warn(3, @msg <> inspect(fallback))
      fallback
    else
      Interpolation.guess_z_value(points, xy)
    end
  end

  def soil_samples do
    from(p in Point,
      where: like(p.meta, "%at_soil_level%"),
      order_by: p.updated_at
    )
    |> Repo.all()
    |> Enum.filter(&is_soil_sample?/1)
    |> index_by_location()
  end

  defp is_soil_sample?(%{meta: %{"at_soil_level" => "true"}}), do: true
  defp is_soil_sample?(_), do: false

  # PROBLEM:
  # * We have many soil readings.
  # * Some readings may be duplicates.
  # * If a soil sample has multiple readings, we only care
  #   about latest version.
  #
  # RULES:
  # * `list` is an Array of `Point` resources ORDERED BY `updated_at`
  #   field, least recently updated points come first. The function
  #   does NOT WORK ON UNSORTED LISTS
  # * Round soil readings to the nearest 10mm.
  # * When two soil readings measure the same spot, always use
  #   the latest value.
  def index_by_location(list) do
    list
    |> Enum.reduce(%{}, fn
      %{x: x, y: y} = value, acc ->
        # If two values have the same X/Y coords, last write
        # wins.
        key = {round_to_10(x), round_to_10(y)}
        Map.put(acc, key, value)

      _, acc ->
        acc
    end)
    |> Map.values()
  end

  defp round_to_10(number), do: round(number / 10) * 10
end
