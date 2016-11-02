defmodule RegimenItem do
  defstruct [ id: nil,
              time_offset: nil,
              regimen_id: nil,
              sequence_id: nil ]
  @type t :: %__MODULE__{
    id: integer,
    time_offset: integer,
    regimen_id: integer,
    sequence_id: integer }

  @spec create(map) :: t
  def create(%{
    "id" => id,
    "time_offset" => time_offset,
    "regimen_id" => regimen_id,
    "sequence_id" => sequence_id})
    when is_integer(id)
     and is_integer(time_offset)
     and is_integer(regimen_id)
     and is_integer(sequence_id)
    do
    %RegimenItem{
      id: id,
      time_offset: time_offset,
      regimen_id: regimen_id,
      sequence_id: sequence_id }
  end
end
