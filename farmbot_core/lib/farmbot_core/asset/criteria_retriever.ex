defmodule FarmbotCore.Asset.CriteriaRetriever do
  alias FarmbotCore.Asset.PointGroup
  @moduledoc """
      __      _ The PointGroup asset declares a list
    o'')}____// of criteria to query points. This
     `_/      ) module then converts that criteria to
     (_(_/-(_/  a list of real points that match the
                criteria of a point group.
     Example: You have a PointGroup with a criteria
              of `points WHERE x > 10`.
              Passing that PointGroup to this module
              will return an array of `Point` assets
              with an x property that is greater than
              10.
    """

    # @number_eq_fields [:radius, :x, :y, :z, :z]
    # @number_gt_fields [:radius, :x, :y, :z, :z]
    # @number_lt_fields [:radius, :x, :y, :z, :z]
    # @string_eq_fields [:name,  :openfarm_slug,  :plant_stage,  :pointer_type]

  def run(%PointGroup{} = _pg) do
  end

  def flatten(%PointGroup{} = pg) do
    {_, results} = ({pg, []}
      # |> handle_meta_fields()
      # |> handle_point_ids()
      |> handle_number_eq_fields()
      |> handle_number_gt_fields()
      |> handle_number_lt_fields()
      |> handle_string_eq_fields()
      |> handle_day_field())
    results
  end

  # # == THIS IS SPECIAL!
  # defp handle_meta_fields({%PointGroup{} = pg, [] = results}) do
  #   raise "Not Implemented"
  #   {pg, results}
  # end

  # # == THIS IS SPEICAL!
  # defp handle_point_ids({%PointGroup{} = pg, [] = results}) do
  #   raise "Not Implemented"
  #   {pg, results}
  # end

  defp handle_number_eq_fields({%PointGroup{} = pg, [] = results}) do
    raise "Not Implemented"
    {pg, results}
  end

  defp handle_number_gt_fields({%PointGroup{} = pg, [] = results}) do
    raise "Not Implemented"
    {pg, results}
  end

  defp handle_number_lt_fields({%PointGroup{} = pg, [] = results}) do
    raise "Not Implemented"
    {pg, results}
  end

  defp handle_string_eq_fields({%PointGroup{} = pg, [] = results}) do
    raise "Not Implemented"
    {pg, results}
  end

  defp handle_day_field({%PointGroup{} = pg, [] = results}) do
    raise "Not Implemented"
    {pg, results}
  end
end
