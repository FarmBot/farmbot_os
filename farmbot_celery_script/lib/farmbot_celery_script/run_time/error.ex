defmodule Farmbot.CeleryScript.RunTime.Error do
  @moduledoc """
  CSVM runtime error
  """

  defexception [:message, :farm_proc]
end
