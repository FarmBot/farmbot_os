defmodule Farmbot.CeleryScript.Conversion do
  @moduledoc """
    a converter for 'old' JSON RPC commands into
    'new' celeryscript commands
  """
  alias RPC.Spec.Request, as: Req
  alias Farmbot.CeleryScript.Ast
  require Logger

  @spec rpc_to_celery_script(Req.t) :: :ok | :not_implemented
  @doc """
    Converts an "old" Farmbot.js style JSON-RPC command to
    the more "modern" Celery Script implementation.
    These commands will actually cause movements, pin toggles, etc.
  """
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
    :ok
  end

  def rpc_to_celery_script(%Req{
    method: "exec_sequence",
    id: _,
    params: [sequence]
    })
  do
    spawn fn() ->
      sequence
      |> Ast.parse
      |> Farmbot.CeleryScript.Command.mutate_sequence(Map.get(sequence, "name"))
      |> Farmbot.CeleryScript.Command.do_command
    end
    :ok
  end

  # havent converted this yet.
  def rpc_to_celery_script(%Req{} = rpc) do
    Logger.warn "#{rpc.method} has no conversion yet. (this is ok)"
    :not_implemented
  end
end
