defmodule FarmbotOS.TimeUtils do
  @moduledoc "Helper functions for working with time."

  @doc """
  Compares a datetime with another.
  • -1 -- the first date comes before the second one
  • 0  -- both arguments represent the same date when coalesced to the same
    timezone.
  • 1  -- the first date comes after the second one

  Returns :gt if the first datetime is later than the second and :lt for vice
  versa. If the two datetimes are equal :eq is returned.
  """
  def compare_datetimes(left, right) do
    case Timex.compare(left, right, :seconds) do
      -1 -> :lt
      0 -> :eq
      1 -> :gt
    end
  end
end
