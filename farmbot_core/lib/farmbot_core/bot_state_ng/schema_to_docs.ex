defmodule Farmbot.BotStateNG.Schema2Docs do
  alias Farmbot.BotStateNG

  def schema_to_ts do
    ts =
      run()
      |> render_dts()
      |> Enum.join("\n")

    ts = """
    export interface BotStateTree {
      #{ts}
    }
    """

    File.write("/tmp/results.ts", ts)
    {formatted, 0} = System.cmd("tsfmt", ["/tmp/results.ts"])
    File.write!("/tmp/results.ts", formatted)
  end

  def run(module \\ BotStateNG) do
    module.__schema__(:dump)
    |> Enum.reduce(%{}, &do_extract/2)
  end

  def render_dts(results, level \\ 1) do
    Enum.map(results, fn {key, type} ->
      key = to_string(key)

      case type do
        %{} = type ->
          record_type =
            type
            |> render_dts(level + 1)
            |> Enum.join("\n\t")

          key <> ": " <> "{\n\t\t" <> record_type <> "\n\t};"

        {:map, {inner, outer}} ->
          inner = type_to_js(inner)
          outer = type_to_js(outer)
          key <> ": " <> "Record<#{inner}, #{outer}>;"

        type ->
          key <> ": " <> type_to_js(type) <> ";"
      end
    end)
  end

  defp type_to_js(:boolean), do: "boolean"
  defp type_to_js(:string), do: "string"
  defp type_to_js(:integer), do: "number"
  defp type_to_js(:float), do: "number"
  defp type_to_js(:map), do: "Record<any, any>"
  defp type_to_js(:any), do: "any"

  def do_extract({key, {key, {:embed, %{related: module}}}}, acc) do
    value = run(module)
    Map.put(acc, key, value)
  end

  def do_extract({key, {key, type}}, acc) do
    Map.put(acc, key, type)
  end
end
