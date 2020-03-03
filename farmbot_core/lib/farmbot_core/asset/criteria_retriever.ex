defmodule FarmbotCore.Asset.CriteriaRetriever do
  alias FarmbotCore.Asset.{ PointGroup, Repo, Point }
  import Ecto.Query

  @moduledoc """
    The PointGroup asset declares a list
    of criteria to query points. This
    module then converts that criteria to
    a list of real points that match the
    criteria of a point group.

    Example:

    You have a PointGroup with a criteria
    of `points WHERE x > 10`.
    Passing that PointGroup to this module
    will return an array of `Point` assets
    with an x property that is greater than
    10.
    """

  @numberic_fields ["radius", "x", "y", "z"]
  @string_fields ["name", "openfarm_slug", "plant_stage", "pointer_type"]

  @doc """
  You provide it a %PointGroup{},
  it provides you an array of
  point IDs (int) that match
  the group's criteria.
  """
  def run(%PointGroup{point_ids: static_ids} = pg) do
    # = = = Handle point_id criteria
    always_ok = Repo.all(from(p in Point, where: p.id in ^static_ids, select: p))
    # = = = Handle AND criteria
    dynamic_ids = find_matching_point_ids(pg)
    dynamic_query = from(p in Point, where: p.id in ^dynamic_ids, select: p)
    needs_meta_filter = Repo.all(dynamic_query)
    # = = = Handle meta.* criteria
    search_matches = search_meta_fields(pg, needs_meta_filter)

    Enum.uniq_by((search_matches ++ always_ok), fn p -> p.id end)
  end

  def search_meta_fields(%PointGroup{} = pg, points) do
    meta = "meta."
    meta_len = String.length(meta)

    (pg.criteria["string_eq"] || %{})
      |> Map.to_list()
      |> Enum.filter(fn {k, _v} ->
        String.starts_with?(k, meta)
      end)
      |> Enum.map(fn {k, value} ->
        clean_key = String.slice(k, ((meta_len)..-1))
        {clean_key, value}
      end)
      |> Enum.reduce(%{}, fn {key, value}, all ->
        all_values = all[key] || []
        Map.merge(all, %{key => value ++ all_values})
      end)
      |> Map.to_list()
      |> Enum.reduce(points, fn {key, values}, finalists ->
        finalists
          |> Enum.filter(fn point -> point.meta[key] end)
          |> Enum.filter(fn point -> point.meta[key] in values end)
      end)
  end

  def matching_ids_no_meta(%PointGroup{} = pg) do
    find_matching_point_ids(pg)
  end

  # Find all point IDs that are matched by a PointGroup
  # This is not including any meta.* search terms,
  # since `meta` is a JSON coolumn that must be
  # manually searched in memory.
  defp find_matching_point_ids(%PointGroup{} = pg) do
    results = {pg, []}
     |> stage_1("string_eq", @string_fields, "IN")
     |> stage_1("number_eq", @numberic_fields, "IN")
     |> stage_1("number_gt", @numberic_fields, ">")
     |> stage_1("number_lt", @numberic_fields, "<")
     |> stage_1_day_field()
     |> unwrap_stage_1()
     |> Enum.reduce(%{}, &stage_2/2)
     |> Map.to_list()
     |> Enum.reduce({[], [], 0}, &stage_3/2)
     |> unwrap_stage_3()
     |> finalize()

     results
  end

  def finalize({_, []}) do
    []
  end

  def finalize({fragments, criteria}) do
    x = Enum.join(fragments, " AND ")
    sql = "SELECT id FROM points WHERE #{x}"
    {:ok, query} = Repo.query(sql, List.flatten(criteria))
    %Sqlite.DbConnection.Result{ rows: rows } = query
    List.flatten(rows)
  end

  defp unwrap_stage_1({_, right}), do: right
  defp unwrap_stage_3({query, args, _count}), do: {query, args}

  defp stage_1({pg, accum}, kind, fields, op) do
    results = fields
      |> Enum.map(fn field -> {field, pg.criteria[kind][field]} end)
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.map(fn {k, v} -> {k, op, v} end)
      {pg, accum ++ results}
  end

  defp stage_1_day_field({pg, accum}) do
    day_criteria = pg.criteria["day"] || %{}
    days = day_criteria["days_ago"] || 0
    if days == 0 do
      { pg, accum }
    else
  
      op = day_criteria["op"] || "<"
      time = Timex.shift(Timex.now(), days: -1 * days)
  
      { pg, accum ++ [{"created_at", op, time}] }
    end
  end

  defp stage_2({lhs, "IN", rhs}, results) do
    query = "#{lhs} IN"
    all_values = results[query] || []
    Map.merge(results, %{query => rhs ++ all_values})
  end

  defp stage_2({lhs, op, rhs}, results) do
    Map.merge(results, %{"#{lhs} #{op}" => rhs})
  end

  defp stage_3({sql, args}, {full_query, full_args, count0}) when is_list(args) do
    final = count0 + Enum.count(args) - 1
    initial_state = {sql, count0}
    {next_sql, _} = Enum.reduce(args, initial_state, fn
      (_, {sql, ^count0}) -> {sql <> " ($#{count0},", count0+1}
      (_, {sql, ^final}) -> {sql <> " $#{final})", final}
      (_, {sql, count}) -> {sql <> " $#{count},", count+1}
    end)

    {full_query ++ [next_sql], full_args ++ [args], final + 1}
  end

  defp stage_3({sql, args}, {full_query, full_args, count}) do
    {full_query ++ [sql <> " $#{count}"], full_args ++ [args], count + 1}
  end
end
