defmodule ExCoveralls.StatServer do
  @moduledoc """
  Provide data-store for coverage stats.
  """

  def start do
    Agent.start(fn -> MapSet.new end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def add(report) do
    Agent.update(__MODULE__, &MapSet.put(&1, report))
  end

  def get do
    Agent.get(__MODULE__, &(&1))
  end
end
