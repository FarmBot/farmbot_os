defmodule Farmbot.CeleryScript.AST.Arg.Device do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: {:ok, val}
  def encode(val), do: {:ok, val}
end

defmodule Farmbot.CeleryScript.AST.Arg.FarmEvents do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: {:ok, val}
  def encode(val), do: {:ok, val}
end

defmodule Farmbot.CeleryScript.AST.Arg.Points do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: {:ok, val}
  def encode(val), do: {:ok, val}
end

defmodule Farmbot.CeleryScript.AST.Arg.Peripherals do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: {:ok, val}
  def encode(val), do: {:ok, val}
end

defmodule Farmbot.CeleryScript.AST.Arg.Regimens do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: {:ok, val}
  def encode(val), do: {:ok, val}
end

defmodule Farmbot.CeleryScript.AST.Arg.Tools do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: {:ok, val}
  def encode(val), do: {:ok, val}
end

defmodule Farmbot.CeleryScript.AST.Arg.ToolSlots do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: {:ok, val}
  def encode(val), do: {:ok, val}
end

defmodule Farmbot.CeleryScript.AST.Node.DataUpdate do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:value, :device, :farm_events, :points, :peripherals, :regimens, :sequences, :tool_slots, :tools]

  def execute(_, _, env) do
    {:ok, env}
  end
end
