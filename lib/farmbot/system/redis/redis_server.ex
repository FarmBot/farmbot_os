defmodule Redis.Server do
  @moduledoc """
    Port for a redis server
  """
  @config Application.get_all_env(:farmbot)[:redis]

  if Mix.env() == :dev do
    def should_bind, do: "bind 0.0.0.0"
  else
    def should_bind, do: "bind 127.0.0.1"
  end

  def config(path: dir), do: ~s"""
  #{should_bind()}
  protected-mode yes
  port #{@config[:port]}
  tcp-backlog 511
  unixsocket /tmp/redis.sock
  unixsocketperm 700
  timeout 0
  tcp-keepalive 0
  supervised no
  pidfile /var/run/redis_6379.pid
  loglevel notice
  logfile ""
  databases 1
  stop-writes-on-bgsave-error yes
  rdbcompression yes
  rdbchecksum yes
  # dbfilename /tmp/dump.rdb
  dir #{dir}
  slave-serve-stale-data yes
  slave-read-only yes
  repl-diskless-sync no
  repl-diskless-sync-delay 5
  repl-disable-tcp-nodelay no
  slave-priority 100
  appendonly no
  appendfilename "appendonly.aof"
  no-appendfsync-on-rewrite no
  auto-aof-rewrite-percentage 100
  auto-aof-rewrite-min-size 64mb
  hash-max-ziplist-value 64
  zset-max-ziplist-value 64
  client-output-buffer-limit slave 256mb 64mb 60
  client-output-buffer-limit pubsub 32mb 8mb 60
  """

  use GenServer
  use Farmbot.DebugLog
  require Logger

  @doc """
    Start the redis server.
  """
  def start_link(_, opts), do: GenServer.start_link(__MODULE__, [], opts)

  def config_file do
    File.write("/tmp/redis.config", config(path: Farmbot.System.FS.path))
    "/tmp/redis.config"
  end

  def init([]) do
    kill_redis()
    exe = System.find_executable("redis-server")
    port = Port.open({:spawn_executable, exe},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout,
       args: ['#{config_file()}']])
    #  Port.connect(port, self())
     {:ok, port}
  end

  def handle_info({_port, {:data, info}}, port) do
    debug_log info
    {:noreply, port}
  end

  def handle_info({_port, _info}, port) do
    {:noreply, port}
  end

  def kill_redis do
    Logger.info "trying to kill old redis"
    case System.cmd("killall", ["redis-server"]) do
      {_, 0} ->
        Process.sleep(5000)
      _ -> :ok
    end
  end

  def terminate(_, _port) do
    kill_redis()
  end
end
