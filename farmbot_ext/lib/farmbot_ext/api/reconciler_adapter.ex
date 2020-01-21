defmodule FarmbotExt.API.ReconcilerAdapter do
  @type sync_changeset :: Changeset.t(any())
  @type sync_items :: list(any())
  @type sync_result :: sync_changeset | {:error, term()}

  @callback sync_group(sync_changeset, sync_items) :: sync_result
end
