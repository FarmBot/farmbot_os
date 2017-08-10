defmodule Farmbot.Bootstrap.Authorization do
  @moduledoc "Functionality responsible for getting a JWT."

  @doc "Supervisor worker child spec for an authorization implementation."
  @spec child_spec(module, Supervisor.options) :: Supervisor.Spec.spec()
  def child_spec(module, opts) do
    {module, {module, :authorize, []}, :permanent, 5000, :worker, [module]}
  end

  @doc """
  Callback for an authorization implementation.
  Should return {:ok, }
  """
  @callback authorize(Supervisor.options) :: Supervisor.Spec.on_start_child()

  @doc """
  Get a token from an implementation.
  """
  @callback get_token()
end
