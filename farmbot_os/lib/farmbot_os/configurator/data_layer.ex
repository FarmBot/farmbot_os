defmodule FarmbotOS.Configurator.DataLayer do
  @callback load_last_reset_reason() :: nil | String.t()
  @callback load_email() :: nil | String.t()
  @callback load_password() :: nil | String.t()
  @callback load_server() :: nil | String.t()
  @callback dump_logs() :: [map()]
  @callback dump_log_db() :: {:error, File.posix()} | binary()
end
