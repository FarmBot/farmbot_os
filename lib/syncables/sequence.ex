defmodule Sequence do
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

  @spec create(map) :: t
  def create(%{"args" => args,
               "body" => body,
               "color" => color,
               "device_id" => device_id,
               "kind" => "sequence",
               "id" => id,
               "name" => name}) do
    %Sequence{args: args,
              body: body,
              color: color,
              device_id: device_id,
              id: id,
              kind: "sequence",
              name: name }
  end
end
