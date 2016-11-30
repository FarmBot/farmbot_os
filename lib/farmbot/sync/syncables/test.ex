defmodule TestSyncable do
  use Syncable,
    name: __MODULE__,
    model: [:id, :name]
end
