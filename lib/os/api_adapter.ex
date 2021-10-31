defmodule FarmbotOS.APIAdapter do
  @callback get_changeset(module) :: {:ok, %Ecto.Changeset{}} | {:error, term()}
  @callback get_changeset(data :: module | map(), Path.t()) ::
              {:ok, %Ecto.Changeset{}} | {:error, term()}
end
