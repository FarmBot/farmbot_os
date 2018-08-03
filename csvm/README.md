[![CircleCI](https://circleci.com/gh/FarmBot-Labs/csvm/tree/master.svg?style=svg)](https://circleci.com/gh/FarmBot-Labs/csvm/tree/master)
[![Coverage Status](https://coveralls.io/repos/github/FarmBot-Labs/csvm/badge.svg?branch=master)](https://coveralls.io/github/FarmBot-Labs/csvm?branch=master)

# CSVM

# Init

```elixir
{:ok, pid} = Csvm.start_link(MyInteractionHandler)
```

# Inbound Message

## External Public CSVM API

The current FarmbotOS implementation expects _every_ CeleryScript request to block.
For example When a FarmEvent is ready for execution, it does:
```elixir
Farmbot.CeleryScript.execute(ast)
```

Ideally in the new implementation, we will have one more available function:
```elixir
# blocking
CSVM.schedule(ast)

# or async
ref = CSVM.async_schedule(ast)
some_other_stuff()
CSVM.await(ref) # later
```

Where `schedule/1` == `execute/1`.

### Example of the IOHandler behaviour and implementation.
```elixir
# The behaviour definition.
defmodule CSVM.IOHandler do
  @moduledoc """
  behaviour definition for implementation specific parts of the CSVM.
  """

  @doc "Blocking move to a position."
  @callback move_absolute(vec3, spd_x, spd_y, spd_z) :: :ok | {:error, String.t}

  @doc "Get a point by it's id from some data store."
  @callback get_point(point_id) :: {:ok, vec3} | {:error, String.t}
end

# The test implementation
defmodule CSVM.TestIOHandler do
  @moduledoc "Test implementation for IOHandler"

  def fixture do
    %{
      points: %{
        100: %{x: 1, y: 2, z: 3}
      }
    }
  end

  @behaviour CSVM.IOHandler

  # simulate movement by sleeping for a random amount of time. Obviously this
  # wouldn't be used in a real test implementation
  def move_absolute(_vec3, _spd_x, _spd_y, _spd_z), do: Process.sleep(:rand.uniform(5000))

  def get_point(id), do: fixture()[:points][id]
end

defmodule CSVM.RealIOHandler do
  @moduledoc "Actual FBOS IOHandler"
  @behaviour CSVM.IOHandler

  def move_absolute(vec3, spd_x, spd_y, spd_z) do
    Farmbot.Firmware.move_absolute(vec3, spd_x, spd_y, spd_z)
  end

  def get_point(id) do
    Farmbot.Asset.get_point(id)
  end
end
```
