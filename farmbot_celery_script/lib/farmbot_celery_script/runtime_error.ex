defmodule FarmbotCeleryScript.RuntimeError do
  @moduledoc """
  CeleryScript error raised when a syscall fails.
  Examples of this include a movement failed, a resource was unavailable, etc.
  """
  defexception [:message]
end
