defmodule Farmbot.CeleryScript.Conversion do
  @moduledoc """
    a converter for 'old' JSON RPC commands into
    'new' celeryscript commands
  """
  alias RPC.Spec.Request, as: Req
  alias Farmbot.CeleryScript.Ast
  require Logger

  def rpc_to_celery_script(%Req{
    method: "move_absolute",
    id: _,
    params: [%{"speed" => s, "x" => x, "y" => y, "z" => z}]})
  do
    %Ast{kind: "move_absolute",
         body: [],
         args: %{location:
                  %Ast{kind: "coordinate",
                       args: %{x: x, y: y, z: z},
                       body: []
                       },
                 offset:
                  %Ast{kind: "nothing",
                       args: %{},
                       body: []
                    },
                 speed: s}}
    |> Farmbot.CeleryScript.Command.do_command
  end

  # havent converted this yet.
  def rpc_to_celery_script(_), do: :not_implemented
end
