defmodule FarmbotCore.Asset.CriteriaRetriever do
  alias FarmbotCore.Asset.{
    PointGroup,
    Repo,
    # Point
  }
  # import Ecto.Query

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
    # = = = Handle AND criteria
    {query, criteria} = flatten(pg) |> normalize() |> to_sql()
    x = Repo.query(query, criteria)
    IO.puts("FIX THIS SYNTAX ERROR. COnvert ? to $123. WILL BE HARD FOR ARRAYS")
    IO.inspect(x)
    []
    # = = = Handle point_id criteria
    # = = = Handle meta.* criteria
  end

  # Map/Reduce operations to convert a %PointGroup{}
  # to a list of SQL queries.
  def flatten(%PointGroup{} = pg) do
    {pg, []}
     |> stage_1("string_eq", @string_fields, "IN")
     |> stage_1("number_eq", @numberic_fields, "IN")
     |> stage_1("number_gt", @numberic_fields, ">")
     |> stage_1("number_lt", @numberic_fields, "<")
     |> stage_1("day")
     |> unwrap()
    end

  def normalize(list) do
    list
    |> Enum.reduce(%{}, &stage_2/2)
    |> Map.to_list()
    |> Enum.reduce({[], []}, &stage_3/2)
  end

  def to_sql({fragments, criteria}) do
    queries = fragments
      |> Enum.with_index
      |> Enum.map(fn {str, inx} -> String.replace(str, "?", "$#{inx}") end)
      |> Enum.join(" AND ")

    {"SELECT id FROM points WHERE #{queries}", criteria}
  end

  defp unwrap({_pg, accum}), do: accum

  defp stage_1({pg, accum}, kind, fields, op) do
    results = fields
      |> Enum.map(fn field -> {field, pg.criteria[kind][field]} end)
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.map(fn {k, v} -> {k, op, v} end)
      {pg, accum ++ results}
  end

  defp stage_1({pg, accum}, "day") do
    op = pg.criteria["day"]["op"] || "<"
    days = pg.criteria["day"]["days_ago"] || 0
    time = Timex.shift(Timex.now(), days: -1 * days)

    { pg, accum ++ [{"created_at", op, time}] }
  end

  defp stage_2({lhs, "IN", rhs}, results) do
    query = "(#{lhs} IN ?)"
    all_values = results[query] || []
    Map.merge(results, %{query => rhs ++ all_values})
  end

  defp stage_2({lhs, op, rhs}, results) do
    query = "(#{lhs} #{op} ?)"
    Map.merge(results, %{query => rhs})
  end

  defp stage_3({next_query, next_fragment}, {query, fragments}) do
    {query ++ [next_query], fragments ++ [next_fragment]}
  end
end
