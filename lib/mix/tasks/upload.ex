defmodule Mix.Tasks.Farmbot.Upload do
  @moduledoc false
  use Mix.Task
  require IEx

  @shortdoc "Uploads a file to a url"

  def run(opts) do
    otp_app = Mix.Project.config[:app]
    target = Mix.Project.config[:target]

    {keywords, [ip_address], _} =
      opts |> OptionParser.parse(switches: [signed: :boolean])

    signed_bool = Keyword.get(keywords, :signed, false)
    file_name = Path.join(["images", "#{Mix.env()}", "#{target}", find_file_name(otp_app, signed_bool)])
    unless File.exists?(file_name) do
      Mix.raise("Could not find firmware: #{file_name}")
    end
    Mix.shell.info "Uploading firmware: #{file_name}"

    start_httpc()
    http_opts = [relaxed: true, autoredirect: true]
    opts = []

    {:ok, file} = :file.read_file('#{file_name}')
    file = :binary.bin_to_list(file)
    url = 'http://#{ip_address}/api/upload_firmware'
    boundary = '------------a450glvjfEoqerAc1p431paQlfDac152cadADfd'
    content_type = :lists.concat(['multipart/form-data; boundary=', boundary])
    body = format_multipart_formdata(boundary, [], [{:firmware, 'firmware.fw', file}])
    headers = [{'Content-Length', :erlang.integer_to_list(:erlang.length(body))}]

    Mix.shell.info "Starting FW upload."

    :httpc.request(:post,
      {url, headers, content_type, body},
      http_opts, opts)
    |> response
  end

  defp start_httpc() do
    Application.ensure_started(:inets)
    Application.ensure_started(:ssl)
    :inets.start(:httpc, profile: :farmbot_firmware)

    opts = [
      max_sessions: 8,
      max_keep_alive_length: 4,
      max_pipeline_length: 4,
      keep_alive_timeout: 120_000,
      pipeline_timeout: 60_000
    ]
    :httpc.set_options(opts, :farmbot_firmware)
  end

  def response({:ok, {{_, 200, _}, _, _}}) do
    Mix.shell.info "Done"
  end

  def response({:ok, {{_, status_code, _}, _, error}}) do
    Mix.shell.info "\nThere was an error applying the firmware: #{inspect status_code} #{inspect error}"
  end

  def response({:error, error}) do
    Mix.shell.info "\nThere was an error applying the firmware: #{inspect error}"
  end

  defp find_file_name(otp_app, true), do: "#{otp_app}-signed.fw"
  defp find_file_name(otp_app, false), do: "#{otp_app}.fw"

  # i stole this from: https://gist.github.com/ArthurClemens/dbd70f9b7a4342810d923670a9db0f39
  defp format_multipart_formdata(boundary, fields, files) do
    field_parts = :lists.map(fn({field_name, field_content}) ->
      [:lists.concat(['--', boundary]),
       :lists.concat(['Content-Disposition: form-data; name=\"',
        :erlang.atom_to_list(field_name), '\"']),
       '',
       field_content]
    end, fields)

    field_parts_2 = :lists.append(field_parts)

    file_parts = :lists.map(fn({field_name, file_name, file_content}) ->
      [
        :lists.concat(['--', boundary]),
        :lists.concat(['Content-Disposition: format-data; name=\"',
          :erlang.atom_to_list(field_name),
          '\"; filename=\"', file_name, '\"']),
        :lists.concat(['Content-Type: ', 'application/octet-stream']),
        '',
        file_content
      ]
    end, files)

    file_parts_2 = :lists.append(file_parts)

    ending_parts = [:lists.concat(['--', boundary, '--']), '']
    parts = :lists.append([field_parts_2, file_parts_2, ending_parts])
    :string.join(parts, '\r\n')
  end

end
