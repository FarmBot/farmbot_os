defmodule Mix.Tasks.Farmbot.Firmware.Slack do
  @moduledoc "Upload a firmware to slack."
  @shortdoc "Upload firmware to slack."

  use Mix.Task
  import Mix.Tasks.Farmbot.Env

  def run(opts) do
    token = slack_token()
    {keywords, comment, _} = opts |> OptionParser.parse(switches: [signed: :boolean])
    signed?          = Keyword.get(keywords, :signed, false)
    Application.ensure_all_started(:httpoison)

    fw_file_to_upload = if signed?, do: signed_fw_file(), else: fw_file()
    time     = format_date_time(File.stat!(fw_file_to_upload))
    filename = "#{mix_config(:app)}-#{env()}-#{mix_config(:commit)}#{if signed?, do: "-signed-", else: "-"}#{time}.fw"
    comment  = Enum.join(comment, " ")
    Mix.shell.info [:green, "Uploading: #{filename} (#{fw_file_to_upload})"]
    url       = "https://slack.com/api/files.upload"
    form_data = %{
      :file             => fw_file_to_upload,
      "token"           => token,
      "channels"        => "embedded-systems",
      "filename"        => filename,
      "title"           => filename,
      "initial_comment" => """
      *New Farmbot Firmware!*
      > *_Env_*:       `#{env()}`
      > *_Target_*:    `#{target()}`
      > *_Version_*:   `#{mix_config(:version)}`
      > *_Commit_*:    `#{mix_config(:commit)}`
      > *_Time_*:      `#{time}`
      #{String.trim(comment)}
      """
    }
    payload = Enum.map(form_data, fn({key, val}) -> {key, val} end)
    real_payload = {:multipart, payload}
    headers = [ {'User-Agent', 'Farmbot HTTP Adapter'} ]
    case HTTPoison.post(url, real_payload, headers, [follow_redirect: true]) do
      {:ok, %{status_code: code, body: body}} when code > 199 and code < 300 ->
        if Poison.decode!(body) |> Map.get("ok", false) do
          Mix.shell.info [:green, "Upload complete!"]
        else
          error("#{Poison.decode!(body, pretty: true)}")
        end
      other ->
        error("#{inspect other}")
    end
  end

  defp error(msg) do
    Mix.raise("Upload failed! " <> msg)
  end

  defp format_date_time(%{ctime: {{yr,m,day}, {hr, min, sec}}}) do
    dt = %DateTime{
      hour: hr,
      year: yr,
      month: m,
      day: day,
      minute: min,
      second: sec,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      std_offset: 0,
      utc_offset: 0
    }
    |> Timex.local()
    "#{dt.year}-#{pad(dt.month)}-#{pad(dt.day)}_#{pad(dt.hour)}#{pad(dt.minute)}"
  end

  defp pad(int) do
    if int < 10, do: "0#{int}", else: "#{int}"
  end
end
