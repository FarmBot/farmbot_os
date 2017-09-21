defmodule Farmbot.System.Updates do
  @moduledoc """
    Check, download, apply updates
  """

  @target Mix.Project.config()[:target]
  @path "/tmp/update.fw"
  require Logger
  alias Farmbot.System.FS
  alias Farmbot.{Context, HTTP}

  # TODO(connor): THIS IS A MINOR IMPROVEMENT FROM THE LAST VERSION OF THIS FILE
  # BUT IT DEFINATELY NEEDS FURTHER REFACTORING.

  @spec mod(atom) :: atom
  defp mod(target), do: Module.concat([Farmbot, System, target, Updates])

  defp releases_url(%Context{} = context) do
    {:ok, token} = Farmbot.Auth.get_token(context.auth)
    token.unencoded.os_update_server
  end

  @doc """
    Checks for updates if the bot says so
  """
  def do_update_check do
    context = Farmbot.Context.new()
    if Farmbot.BotState.get_config(context, :os_auto_update) do
      check_and_download_updates(context)
    else
      Logger.info ">> Will not do update check!"
    end
  end

  @doc """
    Checks for updates, and if there is an update, downloads, and applies it.
  """
  @spec check_and_download_updates(Context.t)
    :: :ok | {:error, term} | :no_updates
  def check_and_download_updates(%Context{} = ctx) do
    case check_updates(ctx) do
      {:update, url} ->
        Logger.info ">> has found a new Operating System update! #{url}",
          type: :busy
        install_updates(ctx, url)
      :no_updates ->
        Logger.info ">> is already on the latest Operating System version!",
          type: :success
        :no_updates
      {:error, reason} ->
        Logger.error ">> encountered an error checking for updates! #{reason}"
        {:error, reason}
    end
  end

  @doc """
    Checks for updates
  """
  @spec check_updates(Context.t)
    :: {:update, binary} | :no_updates | {:error, term}
  def check_updates(%Context{} = context) do
    current = Farmbot.BotState.get_os_version(context)
    if String.contains?(current, "rc") do
      msg = "Release Candidate Releases don't currently support updates!"
      Logger.info msg, type: :warn
      :no_updates
    else
      do_http_req(context)
    end
  end

  @spec check_updates(Context.t)
    :: {:update, binary} | :no_updates | {:error, term}
  defp do_http_req(%Context{} = ctx) do
    with {:ok, %{body: body, status_code: 200}} <- HTTP.get(ctx, releases_url(ctx)),
         {:ok, resp} <- Poison.decode(body),
         {:ok, "v" <> version_str} = Map.fetch(resp, "tag_name"),
         {:ok, version} = Version.parse(version_str),
         {:ok, list} = Map.fetch(resp, "assets")
         do
           cur_os_ver_str = Farmbot.BotState.get_os_version(ctx)
           {:ok, cur_ver} = Version.parse(cur_os_ver_str)
           case Version.compare(version, cur_ver) do
             :gt ->
               url = Enum.find(list, fn(item) ->
                 item["name"] == "farmbot-#{@target}-#{version_str}.fw"
               end)["browser_download_url"]

               {:update, url}
             :eq -> :no_updates
             :lt -> :no_updates
           end
         else
           {:ok, %HTTP.Response{body: body, status_code: code}} ->
             {:error, "Http request failed: body: #{body} status_code: #{code}"}
           {:error, _} = err -> err
           :error -> {:error, :unknown_error}
           nil -> {:error, :unknown_error}
         end
  end

  @doc """
    Installs an update from a url
  """
  @spec install_updates(Context.t, String.t) :: no_return
  def install_updates(%Context{} = context, url) do
    # Ignore the compiler warning here.
    # "I'll fix it later i promise" -- Connor Rigby
    # "i promise I will fix this one day..." -- Connor Rigby
    fun = Farmbot.BotState.download_progress_fun(context, "FBOS_OTA")
    path = HTTP.download_file!(context, url, @path, fun)
    case File.stat(path) do
      {:ok, file} ->
        Logger.info "Found file: #{inspect file}", type: :success
      e -> Logger.error "Could not find update file: #{inspect e}"
    end

    setup_post_update()

    mod(@target).install(path)
    Farmbot.System.reboot()
  end

  @doc """
    Will cause `post_install/0` to be called next reboot.
  """
  def setup_post_update do
    FS.transaction fn ->
      Logger.info "Seting up post update!", type: :busy
      path = "#{FS.path()}/.post_update"
      :ok = File.write(path, "DONT CAT ME\r\n")
    end, true
  end

  @spec post_install :: no_return
  def post_install, do: mod(@target).post_install()

  @callback install(binary) :: no_return
  @callback post_install() :: no_return
end
