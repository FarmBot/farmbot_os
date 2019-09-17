defmodule Mix.Tasks.Farmbot.NervesHub do
  use Mix.Task
  alias NimbleCSV.RFC4180, as: CSV
  alias Mix.NervesHubCLI.Shell

  def run([org]) do
    Application.ensure_all_started(:nerves_hub_cli)

    auth = Shell.request_auth()

    case NervesHubUserAPI.Device.list(org, "farmbot", auth) do
      {:ok, %{"data" => data}} ->
        csv_data = to_csv_rows(data)
        File.write!("#{org}-devices.csv", CSV.dump_to_iodata(csv_data))

      {:error, reason} ->
        Mix.raise(reason)
    end
  end

  def to_csv_rows(
        data,
        acc \\ [
          [
            "identifier",
            "status",
            "version",
            "tags",
            "firmware_uuid",
            "last_communication",
            "platform"
          ]
        ]
      )

  def to_csv_rows([%{} = data | rest], acc) do
    row = [
      data["identifier"],
      data["status"],
      data["version"],
      Enum.join(data["tags"], ", "),
      data["firmware_metadata"]["uuid"],
      data["last_communication"],
      data["firmware_metadata"]["platform"]
    ]

    to_csv_rows(rest, [row | acc])
  end

  def to_csv_rows([], acc), do: Enum.reverse(acc)
end
