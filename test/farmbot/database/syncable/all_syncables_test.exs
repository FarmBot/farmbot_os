alias Farmbot.Database
alias Database.Syncable

alias Syncable.Sequence
alias Syncable.Point
alias Syncable.Peripheral
alias Syncable.Regimen
alias Syncable.Tool
alias Syncable.FarmEvent
alias Syncable.Device

defmodule AllSyncablesTestHelper do

  defmacro test_syncable(module, id) do
    quote do

      defmodule Module.concat(["#{unquote(module)}Test"]) do
        use ExUnit.Case, async: false
        use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney


        setup_all do
          Farmbot.TestHelpers.login()
          [
            module: unquote(module),
            id:     unquote(id),
            token:  Farmbot.TestHelpers.login(),
          ]
        end

        test "ensures proper module sanity", %{module: mod} do
          assert unquote(module) == mod
        end

        test "successfully fetches some stuff from the api", %{module: mod} do
          human_readable_name = Module.split(mod) |> List.last
          filename = "successful_#{human_readable_name}"
          use_cassette filename do
            results = mod.fetch({__MODULE__, :callback, []})
            item = Enum.random(results)
            assert item.__struct__ == mod
          end
        end

        test "gets a particular item from the api", %{module: mod, id: id} do
          human_readable_name = Module.split(mod) |> List.last
          filename = "successful_#{human_readable_name}_single"
          use_cassette filename do
            results = mod.fetch(id, {__MODULE__, :callback, []})
            refute is_error?(results)
            assert results.__struct__ == mod
            assert results.id == id
          end
        end

        test "handles errors for stuff from the api", %{module: mod} do
          human_readable_name = Module.split(mod) |> List.last
          filename = "bad_#{human_readable_name}"
          use_cassette filename do
            results = mod.fetch(-1, {__MODULE__, :callback, []})
            assert is_error?(results)
          end
        end

        def callback(results), do: results

        defp is_error?(results)
        defp is_error?({:error, _}), do: true
        defp is_error?(_), do: false

      end
    end
  end

end

defmodule AllSyncablesTest do
  import AllSyncablesTestHelper
  test_syncable Sequence, -1
  test_syncable Point, -1
  test_syncable Peripheral, -1
  test_syncable Regimen, -1
  test_syncable Tool, -1
  test_syncable FarmEvent, -1
  test_syncable Device, -1
end
