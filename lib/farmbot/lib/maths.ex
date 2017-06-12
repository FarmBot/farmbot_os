defmodule Farmbot.Lib.Maths do
  @moduledoc """
    Math related functions.
  """

  @doc """
    Converts millimeters ot steps.
  """
  @spec mm_to_steps(integer, integer) :: integer
  def mm_to_steps(mm, spm), do: mm * spm

  @doc """
    Converts steps to mm.
  """
  # NOTE(Connor), we will round here. This WILL come up at some point im sure.
  # if we never allow sending of steps we should always be able to
  # divide back by spm.
  @spec steps_to_mm(integer, integer) :: integer

  def steps_to_mm(steps, spm) when is_binary(spm) do
    case Integer.parse(spm) do
      {int, _} -> steps_to_mm(steps, int)
      _ ->
        raise "Can not converts steps (#{steps}) to millimeters!" <>
          " #{inspect spm} must be an integer!"
    end
  end

  def steps_to_mm(steps, spm), do: Kernel.div(steps, spm)
end
