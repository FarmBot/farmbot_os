defmodule Farmbot.System.Init do
  @moduledoc "Lets write init.d in Elixir!"

  @doc "OTP Spec."
  @spec fb_init(atom, [term]) :: Supervisor.Spec.spec
  def fb_init(module, args) do
    import Supervisor.Spec
    supervisor(module, args, [restart: :permanent])
  end

  @doc """
  Start an init module.
  returning {:error, reason} will factory reset the system.
  """
  @callback start_link(term, Supervisor.options) :: Supervisor.supervisor
end
