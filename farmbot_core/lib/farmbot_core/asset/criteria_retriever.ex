defmodule FarmbotCore.Asset.CriteriaRetriever do
  alias FarmbotCore.Asset.PointGroup
  @moduledoc """
      __      _ The PointGroup asset declares a list
    o'')}____// of criteria to query points. This
     `_/      ) module then converts that criteria to
     (_(_/-(_/  a list of real points that match the
                criteria of a point group.
     Example: You have a PointGroup with a criteria
              of `points WHERE x > 10`.
              Passing that PointGroup to this module
              will return an array of `Point` assets
              with an x property that is greater than
              10.
    """

   def run(%PointGroup{} = _pg) do
   end
end
