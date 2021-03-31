defmodule ExCoveralls.ConfServer do
  @moduledoc """
  Provide data-store for configuration settings.
  """

  @ets_table :excoveralls_conf_server
  @ets_key :config_key

  @doc """
  Initialize the data-store table.
  """
  def start do
    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc """
  Clear all the data in data-store table.
  """
  def clear do
    if :ets.info(@ets_table) != :undefined do
      :ets.delete_all_objects(@ets_table)
    end
  end

  @doc """
  Get the configuration value.
  """
  def get do
    start()
    :ets.lookup(@ets_table, @ets_key)[@ets_key] || []
  end

  @doc """
  Set the configuration value.
  """
  def set(value) do
    start()
    :ets.insert(@ets_table, {@ets_key, value})
    value
  end
end
