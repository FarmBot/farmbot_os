defmodule FarmbotCore.Asset.CriteriaRetriever do
  alias FarmbotCore.Asset.{PointGroup, Repo, Point}
  import Ecto.Query

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

  @numberic_fields ["radius", "x", "y", "z"]
  @string_fields ["name", "openfarm_slug", "plant_stage", "pointer_type"]

  def run(%PointGroup{} = pg) do
    {_, list} = flatten(pg)

    reducer = fn [expr, op, args], results ->
      from(p in results, where: fragment("? ? ?", ^expr, ^op, ^args))
    end

    and_query = Enum.reduce(list, Point, reducer)
    # = = = Handle AND criteria
    IO.inspect(and_query)

    Repo.all(and_query)
    # = = = Handle point_id criteria
    # = = = Handle meta.* criteria
  end

  def flatten(%PointGroup{} = pg) do
     {pg, []}
      |> handle_number_eq_fields()
      |> handle_number_gt_fields()
      |> handle_number_lt_fields()
      |> handle_string_eq_fields()
      |> handle_day_field()
  end

  defp handle_number_eq_fields({%PointGroup{} = pg, accum}) do
     build(pg, "number_eq", @numberic_fields, "IN", accum)
  end

  defp handle_number_gt_fields({%PointGroup{} = pg, accum}) do
     build(pg, "number_gt", @numberic_fields, ">", accum)
  end

  defp handle_number_lt_fields({%PointGroup{} = pg, accum}) do
     build(pg, "number_lt", @numberic_fields, "<", accum)
  end

  defp handle_string_eq_fields({%PointGroup{} = pg, accum}) do
     build(pg, "string_eq", @string_fields, "IN", accum)
  end

  defp handle_day_field({%PointGroup{} = pg, accum}) do
    op = pg.criteria["day"]["op"] || "<"
    days = pg.criteria["day"]["days_ago"] || 0
    now = Timex.now()
    time = Timex.shift(now, days: -1 * days)

    query = ["created_at", op, time]

    { pg, accum ++ [ query ] }
  end

  defp build(pg, criteria_kind, criteria_fields, op, accum) do
    results = criteria_fields
      |> Enum.map(fn field ->
        {field, pg.criteria[criteria_kind][field]}
      end)
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.map(fn {k, v} -> [k, op, v] end)
      {pg, accum ++ results}
  end
end
