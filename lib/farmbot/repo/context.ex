defmodule Farmbot.Repo.Context do
  @moduledoc """
  Hello Phoenix.
  """

  alias Farmbot.Repo
  alias Repo.{
    Peripheral
  }

  import Ecto.Query

  @doc "Fetch a Peripheral by its id."
  def get_peripheral(id) do
    repo().one(from p in Peripheral, where: p.id == ^id)
  end

  defp repo, do: Repo.current_repo()
end
