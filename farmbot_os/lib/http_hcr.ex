defmodule HTTPHCR do
  @moduledoc "Hot Code Reloading over HTTP"

  @doc "HTTP Reload"
  def http_r(module, branch \\ "staging") do
    {:ok, app} = :application.get_application(module)
    source = module.module_info(:compile)[:source]

    branch
    |> to_url(to_string(app), to_string(source))
    |> Tesla.get!()
    |> Map.fetch!(:body)
    |> Code.eval_string()
  end

  def to_url(branch, "farmbot", source) do
    to_url(branch, "farmbot_os", source)
  end

  def to_url(branch, "farmbot_" <> _ = folder, source) do
    [_ | path] = String.split(source, folder, parts: 2)
    "https://raw.githubusercontent.com/FarmBot/farmbot_os/#{branch}/#{folder}/#{path}"
  end
end
