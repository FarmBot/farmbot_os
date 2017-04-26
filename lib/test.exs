Code.ensure_compiled(Downloader)
Code.ensure_compiled(IEx)
require IEx
IEx

defmodule CParser do
  def parse(str) do
    str
    |> sanitize
    |> do_parse
  end

  defp do_parse(list, acc) do

  end

  defp do_parse([], acc) do
    IO.inspect acc
  end

  defp do_parse([item | rest], acc) do
    case handle(item, rest) do
      {:ignore, amnt} -> do_parse(Enum.drop(amnt), acc)
    end
  end

  defp handle("#ifndef", _rest), do: {:ignore, 1}
  defp handle("#define", _rest), do: {:ignore, 1}
  defp handle("#inclue", _rest), do: {:ignore, 1}

  defp handle(item, rest) do
    IO.puts "UNHANDLED ITEM: #{item}"
  end

  def sanitize(str) do
    String.replace(results, " ", "SPLIT")
    |> String.replace("\n", "SPLIT")
    |> String.split("SPLIT")
    |> Enum.filter(fn(item) -> item != "" end)
  end
end

http = Downloader
{:ok, pid} = http.start_link()
url = "https://raw.githubusercontent.com/FarmBot/farmbot-arduino-firmware/master/src/ParameterList.h"
{:ok, results} = http.get(pid, url)
IO.puts ""
IO.puts results
IEx.pry
