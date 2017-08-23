defmodule FarmbotTestSupport do
  @moduledoc "Test Helpers."
  import Farmbot.DebugLog, only: [color: 1]

  defp error(err) do
    """
    #{color(:RED)}
    Could not connect to Farmbot #{err} server. Tried using creds:
      #{color(:CYAN)}email: #{color(:NC)}#{inspect Application.get_env(:farmbot, :authorization)[:email]    || "No email configured"    }
      #{color(:CYAN)}pass:  #{color(:NC)}#{inspect Application.get_env(:farmbot, :authorization)[:password] || "No password configured" }
    #{color(:RED)}
    Please ensure the #{err} server is up and running, and configured. If you want to skip tests that require #{err} server, Please run:

      #{color(:NC)}mix test --exclude farmbot_#{err}
    """
  end

  def preflight_checks do
    with {:ok, tkn} <- ping_api(),
         :ok <- ping_mqtt(tkn) do
           :ok
         else
           err -> reraise RuntimeError, error(err), []
         end
  end

  defp ping_api do
    server   = Application.get_env(:farmbot, :authorization)[:server]
    email    = Application.get_env(:farmbot, :authorization)[:email]
    password = Application.get_env(:farmbot, :authorization)[:password]
    case Farmbot.Bootstrap.Authorization.authorize(email, password, server) do
      {:error, _reason} -> :api
      {:ok, tkn} -> {:ok, tkn}
    end
  end

  defp ping_mqtt(tkn) do
    url = Farmbot.Jwt.decode!(tkn).mqtt
    case :gen_tcp.connect(to_charlist(url), 1883, [:binary]) do
      {:error, _} -> :mqtt
      {:ok, port} -> :gen_tcp.close(port)
    end
  end
end
