defmodule FarmbotOS.Asset.CriteriaRetriever do
  alias FarmbotOS.Asset.{PointGroup, Repo, Point}
  import Ecto.Query

  @moduledoc """
  The PointGroup asset declares a list
  of criteria to query points. The CriteriaRetriever
  module then converts that criteria to
  a list of real points that match the
  criteria of a point group.

  Example:

  You have a PointGroup with a criteria
  where group.criteria.number_gt.x == 10
  Passing that PointGroup to this module
  will return an array of `Point` assets
  with an x property that is greater than
  10.
  """

  # We will not query any string/numeric fields other than these.
  # Updating the PointGroup / Point models may require an update
  # to these fields.
  @numberic_fields ["radius", "x", "y", "z", "pullout_direction"]
  @string_fields ["name", "openfarm_slug", "plant_stage", "pointer_type"]

  @doc """
  You provide it a %PointGroup{},
  it provides you an array of
  point records (%Point{}) that match
  the group's criteria.
  """
  def run(%PointGroup{point_ids: static_ids} = pg) do
    # pg.point_ids is *always* include in search results,
    # even if it does not match pg.criteria in any way.
    always_ok =
      Repo.all(from(p in Point, where: p.id in ^static_ids, select: p))

    # Now we need a list of point IDs that actually match
    # the pg.criteria fields. We only get the ID because
    # we are circumventing Ecto and doing raw SQL.
    # There may be better ways to do this:
    dynamic_ids = find_matching_point_ids(pg)

    # Once we have a list of matching criteria, we can run a
    # SQL query through Ecto to return real %Point{} structs...
    dynamic_query = from(p in Point, where: p.id in ^dynamic_ids, select: p)
    # ...but we're not done! If the criteria contains meta fields,
    # we need to perform a lookup in memory
    needs_meta_filter = Repo.all(dynamic_query)
    # There we go. We have all the matching %Point{}s
    search_matches = search_meta_fields(pg, needs_meta_filter)
    # ...but there are duplicates. We can remove them via uniq_by:
    Enum.uniq_by(search_matches ++ always_ok, fn p -> p.id end)
  end

  @doc """
  Takes intermediate search results and makes them
  more specific by iterating over the search results
  and only returning the ones that match the meta.*
  field provided in pg.criteria
  """
  def search_meta_fields(%PointGroup{} = pg, points) do
    meta = "meta."
    meta_len = String.length(meta)

    (pg.criteria["string_eq"] || %{})
    |> Map.to_list()
    |> Enum.filter(fn {k, _v} ->
      String.starts_with?(k, meta)
    end)
    |> Enum.map(fn {k, value} ->
      clean_key = String.slice(k, meta_len..-1)
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

  # Find all point IDs that are matched by a PointGroup
  # This is not including any meta.* search terms,
  # since `meta` is a JSON column that must be
  # manually searched in memory.
  defp find_matching_point_ids(%PointGroup{} = pg) do
    results =
      {pg, []}
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

  # EDGE CASE: If the user _only_ wants to put static points
  # in their group, we need to perform 0 SQL queries.
  def finalize({_, []}) do
    []
  end

  def finalize({fragments, criteria}) do
    x = Enum.join(fragments, " AND ")
    sql = "SELECT id FROM points WHERE #{x}"
    query_params = List.flatten(criteria)
    {:ok, query} = Repo.query(sql, query_params)
    %{rows: rows} = query
    List.flatten(rows)
  end

  defp unwrap_stage_1({_, right}), do: right
  defp unwrap_stage_3({query, args, _count}), do: {query, args}

  defp stage_1({pg, accum}, kind, fields, op) do
    results =
      fields
      |> Enum.map(fn field -> {field, pg.criteria[kind][field]} end)
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.map(fn {k, v} -> {k, op, v} end)

    {pg, accum ++ results}
  end

  defp stage_1_day_field({pg, accum}) do
    day_criteria = pg.criteria["day"] || pg.criteria[:day] || %{}
    days = day_criteria["days_ago"] || day_criteria[:days_ago] || 0
    op = day_criteria["op"] || day_criteria[:op] || "<"
    time = Timex.shift(Timex.now(), days: -1 * days)

    if days == 0 do
      {pg, accum}
    else
      inverted_op =
        if op == ">" do
          "<"
        else
          ">"
        end

      field =
        "CASE
           WHEN pointer_type = 'Plant' THEN
             CASE
               WHEN planted_at IS NULL THEN created_at
               ELSE planted_at
             END
           ELSE created_at
         END"

      {pg, accum ++ [{field, inverted_op, time}]}
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

  # Interpolating data turned out to be hard.
  # Pretty sure there is an easier way to do this.
  # NOT OK: Repo.query("SELECT foo WHERE bar IN $0", [[1, 2, 3]])
  # OK:     Repo.query("SELECT foo WHERE bar IN ($0, $1, $2)", [1, 2, 3])
  defp stage_3({sql, args}, {full_query, full_args, count0})
       when is_list(args) do
    arg_count = Enum.count(args)
    final = count0 + (arg_count - 1)
    initial_state = {sql, count0}

    {next_sql, _} =
      if arg_count == 1 do
        {sql <> " ($#{count0})", nil}
      else
        Enum.reduce(args, initial_state, fn
          _, {sql, ^count0} -> {sql <> " ($#{count0},", count0 + 1}
          _, {sql, ^final} -> {sql <> " $#{final})", final}
          _, {sql, count} -> {sql <> " $#{count},", count + 1}
        end)
      end

    {full_query ++ [next_sql], full_args ++ [args], final + 1}
  end

  defp stage_3({sql, args}, {full_query, full_args, count}) do
    {full_query ++ [sql <> " $#{count}"], full_args ++ [args], count + 1}
  end
end
