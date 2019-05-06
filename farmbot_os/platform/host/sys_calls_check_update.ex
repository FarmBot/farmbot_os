defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false

  @doc false
  def check_update do
    {:error,
     """
     Over the air updates not available in this environment.
     """}
  end
end
