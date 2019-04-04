defmodule FarmbotFirmware.Project do
  @arduino_commit Mix.Project.config()[:arduino_commit] ||
                    Mix.raise("Missing Project key arduino_commit")

  @doc "*#{@arduino_commit}*"
  @compile {:inline, arduino_commit: 0}
  def arduino_commit, do: @arduino_commit
end
