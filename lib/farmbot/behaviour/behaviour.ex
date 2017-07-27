defmodule Farmbot.Behaviour do
  @moduledoc """
  Farmbot behaviour Should define public functions that can be changed out per
  environment.

  ## Example:

      defmodule Farmbot.Behaviour.SomeFunctionality do
        @moduledoc "Behaviour for some thing."

        @doc "Does some important thing"
        @callback some_method() :: :ok
      end

      defmodule Farmbot.Production.SomeFunctionality do
        @moduledoc "Implements SomeFunctionality in production environment."

        @behaviour Farmbot.Behaviour.SomeFunctionality

        @doc false
        def some_method do
          some_production_thing()
          :ok
        end
      end

      defmodule Farmbot.Test.SomeFunctionality do
        @moduledoc "implements SomeFunctionality for the test environment."

        @behaviour Farmbot.Behaviour.SomeFunctionality

        @doc false
        def some_method do
          some_test_thing()
          :ok
        end
      end
  """
end
