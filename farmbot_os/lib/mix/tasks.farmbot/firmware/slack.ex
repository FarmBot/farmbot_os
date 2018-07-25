defmodule Mix.Tasks.Farmbot.Firmware.Slack do
  @moduledoc "Upload a firmware to slack."
  @shortdoc "Upload firmware to slack."

  use Mix.Task
  import Mix.Tasks.Farmbot.Env

  def run(opts) do
    token = slack_token()

    {keywords, comment, _} =
      opts |> OptionParser.parse(switches: [signed: :boolean, channels: :string])

    signed? = Keyword.get(keywords, :signed, false)
    Application.ensure_all_started(:timex)
    Application.ensure_all_started(:httpoison)

    fw_file_to_upload = if signed?, do: signed_fw_file(), else: fw_file()
    time = format_date_time(File.stat!(fw_file_to_upload))

    filename =
      "#{mix_config(:app)}-#{target()}-#{env()}-#{commit()}#{
        if signed?, do: "-signed-", else: "-"
      }#{time}.fw"

    comment = Enum.join(comment, " ")
    Mix.shell().info([:green, "Uploading: #{filename} (#{fw_file_to_upload})"])
    url = "https://slack.com/api/files.upload"
    channels = Keyword.fetch!(keywords, :channels)

    form_data = %{
      :file => fw_file_to_upload,
      "token" => token,
      "channels" => channels,
      "filename" => filename,
      "title" => filename,
      "initial_comment" => build_comment(time, comment)
    }

    payload = Enum.map(form_data, fn {key, val} -> {key, val} end)
    real_payload = {:multipart, payload}
    headers = [{'User-Agent', 'Farmbot HTTP Adapter'}]

    case HTTPoison.post(url, real_payload, headers, follow_redirect: true) do
      {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 ->
        if Jason.decode!(body) |> Map.get("ok", false) do
          Mix.shell().info([:green, "Upload complete!"])
        else
          error("#{Jason.decode!(body, pretty: true)}")
        end

      other ->
        error("#{inspect(other)}")
    end
  end

  defp error(msg) do
    Mix.raise("Upload failed! " <> msg)
  end
end
