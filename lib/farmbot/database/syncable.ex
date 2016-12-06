defmodule Syncable do
  use Amnesia
  @moduledoc """
    Creates a syncable object from Farmbot's rest api.
    Example:
      iex> defmodule BubbleGum do
      ...>    use Syncable, name: __MODULE__, model: [:flavors, :brands]
      ...> end
      iex> BubbleGum.create!(%{"flavors" => ["mint", "berry"], "brands" => ["BigRed"]})
           {:ok, %BubbleGum{flavors: ["mint", "berry"], brands:  ["BigRed"]}}
  """

  @doc false
  defmacro __using__(name: name, model: model) do
    quote do
      # import Syncable
      @enforce_keys unquote(model)
      generate_validation(unquote(name), unquote(model))

      defp mutate(_k, v), do: {:ok, v}
      defoverridable [mutate: 2]
    end
  end

  @doc """
    Generates The validate functions for validating json data.
  """
  defmacro generate_validation(name, model) do
    quote bind_quoted: [name: name, model: model] do

      # Makes sure that we have AT LEAST the correct keys. Does not check
      # For extras.
      defp validate_keys(keys) do
        required_keys = Enum.map unquote(model), fn(key) -> Atom.to_string(key) end
        blah =  required_keys -- keys
        case blah == [] do
          true -> :valid
          _ -> {:error, unquote(name), {:missing_keys, blah}}
        end
      end

      @doc """
        Makes sure an object can be built given keys:
        #{inspect(Enum.map model, fn(key) -> Atom.to_string(key) end)}
        * makes sure we have atleast:
        #{inspect(Enum.map model, fn(key) -> Atom.to_string(key) end)}
        * Runs any defined mutations
        * returns { :ok, %#{name}{} }
      """
      @spec validate({:ok, map} | map) :: {:ok. t}
      def validate({:ok, map}), do: validate(map)
      def validate(map) when is_map(map) do
        with :valid <- validate_keys(Map.keys(map)),
             {:ok, struct} <- do_validate(map) do
               {:ok, struct}
             end
      end

      def validate(_), do: {:error, unquote(name), :bad_map}
      def validate!(map) do
        case validate(map) do
          {:ok, o} -> o
          fail -> raise("Failed to validate! #{inspect fail}")
        end
      end

      defp do_validate(map) when is_map(map) do
        # creates a map with atom keys rather than strings
        # This map will more than likely have keys that should not exist.
        m = Map.new(map, fn({key, v}) ->
          thing = String.to_atom(key)
          {:ok, value} = mutate(thing, v)
          {thing, value}
        end)

        # ALL THE KEYS THAT WERE GENERATED
        keys = Map.keys(m)
        # Subtract all the good keys so we are left with the bad ones.
        bad_keys = keys -- unquote(model)
        # Drop those keys.
        validated_map = Map.drop(m, bad_keys)

        g = struct!(unquote(name), validated_map)
        {:ok, g}
      end
    end
  end

  @doc """
    Transforms the state before it is entered into the struct.
    Basically you call transform(key) do something end where something will be
    the new value for key.
    Example:
      Iex> defmodule Dog do
      ...>  use Syncable, name: __MODULE__, model: [:legs]
      ...>  mutation :legs do
      ...>    new_thing = before + 1
      ...>    IO.puts "This probably isnt a dog anymore?"
      ...>    new_thing
      ...>  end
      ...> end
      Iex> Dog.create!("legs" => 4)
           This probably isnt a dog anymore?
           %Dog{legs: 5}
  """
  defmacro mutation(key, block) do
    quote do
      defp mutate(unquote(key), var!(before)), unquote(block)
    end
  end

  defmacro syncable(module, model, do_block \\ []) do
    {:__aliases__, _, [thing]} = module
    IO.puts "Defining syncable: #{inspect thing}, with keys: #{inspect model}"
    quote do
      deftable unquote(module)
      deftable unquote(module), unquote(model), type: :bag do
        use Syncable, name: __MODULE__, model: unquote(model)
        @moduledoc """
          A #{unquote(module)} from the API.
          \nRequires: #{inspect unquote(model)}
        """

        # Allow user to define other stuff inside this module
        unquote do_block
        # Throw this at the bottom so if the user definves a mutation
        # They wont need to account for all keys.
        defp mutate(_k, v), do: {:ok, v}
      end
    end
  end

  @doc """
    Builds a function for getting a module by id
  """
  defmacro get_by_id(name) do
    module_name = Module.concat(Farmbot.Sync.Database, Macro.camelize(name))
    function_name = String.to_atom("get_" <> name)
    quote do
      def unquote(function_name)(find_id) do
        Amnesia.transaction do
          m = unquote(module_name)
          m.read(find_id)
        end
      end
    end
  end

end
