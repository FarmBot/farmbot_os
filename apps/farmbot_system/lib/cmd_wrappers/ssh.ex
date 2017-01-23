defmodule Farmbot.System.Network.SSH do
  @moduledoc """
    Module to manage SSH via an Erlang port.
  """
  use GenServer
  require Logger
  alias Farmbot.System.FS

  @banner "/tmp/banner"
  @cmd "dropbear -R -F -a -B -E -b #{@banner}"
  @var_run_dir "/var/run/dropbear"

  def init(_) do
    Logger.debug ">> Is starting SSH service."
    Process.flag(:trap_exit, true)
    make_banner()

    # this is where dropbear puts keys and stuff.
    if !File.exists? @var_run_dir do
      Logger.debug ">> needs to create a place for ssh keys."
      File.mkdir_p @var_run_dir
    end

    if File.exists? "#{FS.path()}/dropbear_ecdsa_host_key" do
      Logger.debug ">> loading old ssh keys"
      File.cp "#{FS.path()}/dropbear_ecdsa_host_key", @var_run_dir
    end

    port = open_port()
    {:ok, port}
  end

  def open_port() do
    Port.open({:spawn, @cmd},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout])
  end

  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def stop(reason) do
    GenServer.stop(__MODULE__, reason)
  end

  def handle_info({:EXIT, port, reason}, state)
  when state == port do
    Logger.error ">>`s ssh client died: #{inspect reason}"
    new_state = open_port()
    {:noreply, new_state}
  end

  def handle_info({_, {:data, data}}, port) when is_bitstring(data) do
    Logger.debug ">> got ssh data: #{String.trim(data)}"
    save_contents()
    {:noreply, port}
  end

  def handle_info(_i, port) do
    {:noreply, port}
  end

  def terminate(_reason, _state) do
    save_contents()
  end

  def save_contents do
    Logger.debug ">> Saving ssh keys"
    case File.read "#{@var_run_dir}/dropbear_ecdsa_host_key" do
      {:ok, c} ->
        FS.transaction fn() ->
          File.write "#{FS.path()}/dropbear_ecdsa_host_key", c
        end
      _ -> :ok
    end
    :ok
  end

  def make_banner do
    contents =
    """
    __________________________________________________________________
    | WELCOME TO FARMBOT SHELL. I AM TRULY SORRY YOU HAVE TO BE HERE |
    |_______________________________|________________________________|
    |       THERE IS NO $PATH       |        THERE IS NO BASH        |
    |         THERE IS NO SU        |       THERE IS NO APT-GET      |
    |        THERE IS NO MAKE       |        THERE IS NO WGET        |
    |_______________________________|________________________________|
    """
    File.write(@banner, contents)
  end
end
