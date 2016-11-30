defmodule Sequence do
  @moduledoc """
    Sequence Object
  """
  defstruct [args: nil,
             body: nil,
             color: nil,
             device_id: nil,
             id: nil,
             kind: "sequence",
             name: nil]
 @type t :: %__MODULE__{args: map,
                        body: list,
                        color: String.t,
                        device_id: integer,
                        id: integer,
                        kind: String.t,
                        name: String.t}

  @spec create(map) :: {:ok, t} | {atom, :malformed}
  def create(
    %{"args" => args,
      "body" => body,
      "color" => color,
      "device_id" => device_id,
      "kind" => "sequence",
      "id" => id,
      "name" => name})
  do
    f =
    %Sequence{args: args,
              body: body,
              color: color,
              device_id: device_id,
              id: id,
              kind: "sequence",
              name: name}
    {:ok, f}
  end
  def create(_), do: {__MODULE__, :malformed}

  @spec create!(map) :: t
  def create!(thing) do
    case create(thing) do
      {:ok, success} -> success
      {__MODULE__, :malformed} -> raise "Malformed #{__MODULE__} Object"
    end
  end
end
