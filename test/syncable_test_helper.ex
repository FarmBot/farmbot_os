defmodule SyncableHelper do
  defmacro __using__(module) do
    quote do
      use Syncables
      # IM SO SORRY ABOUT THIS
      defp syncable do
        m = unquote(module)
        m
        |> Atom.to_string
        |> String.split("Test")
        |> List.delete("")
        |> List.first
        |> String.to_atom
      end

      defp good_model(model) when is_list(model) do
        # [:a, :b, :c] should return %{"a" => a, "b" => b, "c" => c}
        f = Enum.reduce(model, [], fn(key), acc ->
          [{
            Atom.to_string(key),
            "fake_data"
          }] ++ acc
        end)
        {res, _} = {:%{}, [], f} |> Code.eval_quoted
        res
      end

      test "Creates a syncable object and does not raise errors" do
        model = syncable.model
        {:ok, thing} = syncable.create(good_model(model))
        other_thing = syncable.create!(good_model(model))
        assert is_map(thing) == true
        assert thing == other_thing
      end

      test "Doesnt create an object missing feilds" do
        model = syncable.model
        {module_name, error} = syncable.create(%{"fail" => "its wrong!"})
        IO.inspect error
        assert module_name == syncable
        assert error == {:missing_keys, model}
      end

      test "an object Doesnt except bad types " do
        {module_name, error} = syncable.create([:what, :is, :this])
        assert module_name == syncable
        assert error == :malformed
      end

      # Sorry about this one too
      test "raises an exception if invalid" do
        model = syncable.model
        assert_raise RuntimeError,
        "#{inspect syncable} {:missing_keys, #{inspect model}} expecting: #{inspect model}",
        fn ->
          syncable.create!(%{"fake" => "data"})
        end
      end

    end
  end
end
