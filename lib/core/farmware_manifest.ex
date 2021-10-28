defmodule FarmbotCore.FarmwareManifest do
  defstruct package: "",
            args: "",
            config: %{}

  def by_name(name), do: raise("TODO: #{inspect(name)}")
end
