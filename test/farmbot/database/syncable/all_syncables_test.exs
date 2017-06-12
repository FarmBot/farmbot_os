alias Farmbot.Database
alias Database.Syncable

alias Syncable.Sequence
alias Syncable.Point
alias Syncable.Peripheral
alias Syncable.Regimen
alias Syncable.Tool
alias Syncable.FarmEvent
# alias Syncable.Device

alias Farmbot.Context

defmodule AllSyncablesTestHelper do

  defmacro test_syncable(module, id) do
    quote do

      defmodule Module.concat(["#{unquote(module)}Test"]) do
        use ExUnit.Case, async: false

        setup_all do
          context = Context.new()
          [
            module:     unquote(module),
            id:         unquote(id),
            cs_context: Farmbot.Test.Helpers.login(context),
          ]
        end

        test "ensures proper module sanity", %{module: mod} do
          assert unquote(module) == mod
        end

        test "successfully fetches some stuff from the api", %{module: mod, cs_context: ctx} do
          human_readable_name = Module.split(mod) |> List.last
          results = mod.fetch(ctx, {__MODULE__, :callback, []})
          item = Enum.random(results)
          assert item.__struct__ == mod

        end

        unless unquote(id) == :no_show do
          test "gets a particular item from the api", %{module: mod, id: id, cs_context: ctx} do
            human_readable_name = Module.split(mod) |> List.last
            results = mod.fetch(ctx, id, {__MODULE__, :callback, []})
            refute is_error?(results)
            assert results.__struct__ == mod
            assert results.id == id
          end
        end


        # test "handles errors for stuff from the api", %{module: mod, cs_context: ctx} do
        #   human_readable_name = Module.split(mod) |> List.last
        #   results = mod.fetch(ctx, -1, {__MODULE__, :callback, []})
        #   assert is_error?(results)
        # end


        def callback(results), do: results
        # 
        # defp is_error?(results)
        # defp is_error?({:error, _}), do: true
        defp is_error?(_), do: false

      end
    end
  end

end

defmodule AllSyncablesTest do
  import AllSyncablesTestHelper
  test_syncable Sequence,   2
  test_syncable Point,      71
  test_syncable Tool,       1
  test_syncable FarmEvent,  :no_show
  test_syncable Peripheral, :no_show
  test_syncable Regimen,    :no_show
  # test_syncable Device, -1
end
