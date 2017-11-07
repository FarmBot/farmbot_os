defmodule ParamParser do
  def run do
    File.read!("params.txt") |> String.replace("\t", " ") |> String.split("\n") |> do_run()
  end

  def do_run(list, acc \\ {[], []})

  def do_run(["" | rest], acc), do: do_run(rest, acc)

  def do_run([param | rest], {strs, nums}) do
    {param, num} = parse_param(param)
    do_run(rest, {[param | strs], [num | nums]})
  end

  def do_run([], {strs, nums}) do
    res = do_build_parse_num(strs, nums)
          ++ [""]
          ++ do_build_parse_str(strs, nums)
          ++ [""]
          ++ build_type(Enum.reverse(strs))
          |> Enum.join("\n")
    File.write!("blah.exs", res)
  end

  def parse_param(param) do
    list = String.split(String.trim(param), " ")
    num = List.first(list) |> String.to_integer()
    param = List.last(list) |> String.downcase()
    {param, num}
  end

  defp do_build_parse_num(strs, nums, acc \\ [])
  defp do_build_parse_num([str | strs], [num | nums], acc) do
    built = "def parse_param(#{num}), do: :#{str}"
    do_build_parse_num(strs, nums, [built | acc])
  end

  defp do_build_parse_num([], [], acc), do: acc

  defp do_build_parse_str(strs, nums, acc \\ [])
  defp do_build_parse_str([str | rest_strs], [num | num_strs], acc) do
    built = "def parse_param(:#{str}), do: #{num}"
    do_build_parse_str(rest_strs, num_strs, [built | acc])
  end

  defp do_build_parse_str([], [], acc), do: acc

  defp build_type(strs, acc \\ [])

  defp build_type([str | rest], []) do
    built = ":#{str} |"
    build_type(rest, [built])
  end

  defp build_type([str | rest], [curr | old]) when byte_size(curr) > 80 do
    IO.puts "split on #{str}"
    built = ":#{str} | \n"
    build_type(rest, [built | old ++ [curr]])
  end

  defp build_type([str | rest], [curr | old] = acc) do
    built = ":#{str} | "
    build_type(rest, [curr <> built | old])
  end

  defp build_type([], acc) do
    ["@type t :: " <> Enum.join(acc, "")]
  end
end

ParamParser.run()
