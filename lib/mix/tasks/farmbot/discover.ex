defmodule Mix.Tasks.Farmbot.Discover do
  @moduledoc """
  Usage: mix farmbot.discover [OPTS]
  ## OPTS
    * `--print`  - print the output. (Optional)
    * `--format=FORMAT` - format to print. (Optional, ignored if not printing.)

  ## FORMAT
    * `json`  - print as json.
    * `human` - print in human readable form. (default)

  ## Examples
  ```
    $ mix farmbot.discover --print
    %{"cache-control": "max-age=1800", host: "192.168.29.103",
      location: "http://192.168.29.103/ssdp", node: "farmbot@nerves-7e4b",
      server: "Farmbot", service_name: "uuid:4d6ac078-0e4a-4a7a-b6cf-e951e5c959c5",
      st: "nerves:farmbot"}
  ```

  ```
    $ mix farmbot.discover --print --format json
    [{"st":"nerves:farmbot","service_name":"uuid:4d6ac078-0e4a-4a7a-b6cf-e951e5c959c5","server":"Farmbot","node":"farmbot@nerves-7e4b","location":"http://192.168.29.103/ssdp","host":"192.168.29.103","cache-control":"max-age=1800"}]
  ```
  """
  use Mix.Task
  @shortdoc """
  Discovers farmbots on the network via ssdp.
  """

  def run(opts) do
    devices = Nerves.SSDPClient.discover()
      |> Enum.filter(fn({_, device}) -> device.st == "nerves:farmbot" end)
      |> Enum.map(fn({sn, device})   -> Map.put(device, :service_name, sn) end)

    switches      = [print: :boolean, format: :string]
    {kws, _, _}   = OptionParser.parse(opts, switches: switches)
    should_print? = Keyword.get(kws, :print, false)
    if should_print? do
      format = Keyword.get(kws, :format, "human")
      do_print(devices, format)
    end

    devices
  end

  defp do_print(devices, "json") do
    IO.puts Poison.encode!(devices)
  end

  defp do_print([device | rest], format) do
    print_device(device)
    do_print(rest, format)
  end

  defp do_print([], _), do: :ok

  defp print_device(device) do
    IO.inspect device
  end
end
