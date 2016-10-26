defmodule SSH do
  use GenServer
  require Logger
  @banner "/tmp/banner"
  @cmd "dropbear -R -F -a -B -b #{@banner}"
  def init(:prod) do
    Process.flag(:trap_exit, true)
    make_banner
    case File.read("/root/dropbear_ecdsa_host_key") do
      {:ok, contents} ->
        File.write("/etc/dropbear/dropbear_ecdsa_host_key", contents)
        save_contents
      _ -> nil
    end
    {:ok, Port.open({:spawn, @cmd}, [:binary])}
  end

  def init(_) do
    {:ok, nil}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_info({:EXIT, port, reason}, state)
  when state == port do
    Logger.error("SSH died: #{inspect reason} Restarting")
    new_state = Port.open({:spawn, @cmd}, [:binary])
    {:noreply, new_state}
  end

  def handle_info(info, port) do
    IO.inspect info
    {:noreply, port}
  end

  def terminate(_reason, _state) do
    save_contents
  end

  def save_contents do
    case File.read("/etc/dropbear/dropbear_ecdsa_host_key") do
      {:ok, contents} -> File.write("/root/dropbear_ecdsa_host_key", contents)
      _ -> nil
    end
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
