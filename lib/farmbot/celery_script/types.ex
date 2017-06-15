defmodule Farmbot.CeleryScript.Types do
  @moduledoc """
    Common types for shared CeleryScript Nodes.
  """

  alias Farmbot.CeleryScript.Ast

  @typedoc """
    usually either `farmbot_os` | `arduino_firmware` but will also be things
    like:

    * Farmware Names
    * Sync resources.
  """
  @type package :: binary

  @typedoc "X | Y | Z"
  @type axis    :: coord_x_bin | coord_y_bin | coord_z_bin

  @typedoc "The literal string `X`"
  @type coord_x_bin  :: binary

  @typedoc "The literal string `Y`"
  @type coord_y_bin  :: binary

  @typedoc "The literal string `Z`"
  @type coord_z_bin  :: binary

  @typedoc "Integer representing an X coord."
  @type coord_x :: integer

  @typedoc "Integer representing an Y coord."
  @type coord_y :: integer

  @typedoc "Integer representing an X coord."
  @type coord_z :: integer

  @typedoc """
  Ast in the shape of:
  ```
  %Ast{
    kind: "pair",
    args: %{label: binary, value: any},
    body: []
  }
  ```
  """
  @type pair_ast    :: ast

  @typedoc false
  @type pairs_ast   :: [pair_ast]

  @typep coord_args :: %{x: coord_x, y: coord_y, z: coord_z}
  @typedoc """
  Ast in the shaps of:
  ```
  %Ast{
    kind: "coordinate",
    args: %{x: int, y: int, z: int},
    body: []
  }
  ```
  """
  @type coord_ast :: %Ast{kind: binary, args: coord_args, body: []}

  @typedoc """
  Ast in the shape of:
  ```
  %Ast{
    kind: "nothing",
    args: %{},
    body: []
  }
  ```
  """
  @type nothing_ast :: %Ast{kind: binary, args: %{}, body: []}

  @typedoc """
  Ast in the shape of:
  ```
  %Ast{
    kind: "explanation",
    args: %{message: binary},
    body: []
  }
  ```
  """
  @type explanation_ast :: %Ast{kind: binary, args: %{message: binary}, body: []}

  @typedoc "Integer representing a pin on the arduino."
  @type pin_number  :: 0..69

  @typedoc "Integer representing digital (0) or pwm (1)"
  @type pin_mode    :: 0 | 1

  @typedoc false
  @type ast     :: Ast.t
end
