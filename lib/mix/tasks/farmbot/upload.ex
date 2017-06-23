defmodule Mix.Tasks.Farmbot.Upload do
  @moduledoc false
  use Mix.Task
  @shortdoc "Uploads a file to a url"

  def run(opts) do
    otp_app = Mix.Project.config[:app]
    target  = Mix.Project.config[:target]

    {keywords, ip_address} =
      case opts |> OptionParser.parse(switches: [signed: :boolean]) do
        {keywords, [ip_address], _} -> {keywords, ip_address}
        {keywords, [], _}           -> {keywords, try_discover()}
      end

    signed_bool = Keyword.get(keywords, :signed, false)
    file_name   = Path.join(["images", "#{Mix.env()}", "#{target}", find_file_name(otp_app, signed_bool)])

    unless File.exists?(file_name) do
      Mix.raise("Could not find firmware: #{file_name}")
    end

    Mix.shell.info "Trying to uploading firmware: #{file_name}"

    context     = Farmbot.Context.new()
    Registry.start_link(:duplicate,  Farmbot.Registry)
    {:ok, _}    = Farmbot.DebugLog.start_link()
    {:ok, http} = Farmbot.HTTP.start_link(context, [])
    context     = %{context | http: http}
    url         = "http://#{ip_address}"
    ping_url    = "#{url}/api/ping"
    upload_url  = "#{url}/api/upload_firmware"
    Farmbot.HTTP.get! context, ping_url
    Mix.shell.info [:green, "Connected to bot."]

    boundry        = Farmbot.HTTP.Multipart.new_boundry()
    file           = File.read!(file_name)
    payload        = %{firmware: {file_name, file}}
    payload        = Farmbot.HTTP.Multipart.format(payload, boundry)
    ct = Farmbot.HTTP.Multipart.multi_part_header(boundry)
    headers = [ct]

    Mix.shell.info "Uploading..."
    r = Farmbot.HTTP.post! context, upload_url, payload, headers, [timeout: 60_000]
    unless match?(%{status_code: 200}, r) do
      Mix.raise "Failed to upload firmware: #{format r}"
    end

    Mix.shell.info [:green, "Finished!"]
  end

  defp format(%{body: body}), do: body
  defp format(other), do: inspect other

  defp find_file_name(otp_app, true),  do: "#{otp_app}-signed.fw"
  defp find_file_name(otp_app, false), do: "#{otp_app}.fw"

  defp try_discover do
    devices = Mix.Tasks.Farmbot.Discover.run([])
    case devices do
      [device]          -> device.host
      [_device | _more] -> do_raise("detected more than one farmbot.")
      []                -> do_raise("could not detect farmbot.")
    end
  end

  defp do_raise(msg) do
    Mix.raise "#{msg} Please supply the ip address of your bot."
  end
end
