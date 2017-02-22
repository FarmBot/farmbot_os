defmodule Syncable do
  @moduledoc ~s"""
    Creates a syncable object from Farmbots rest api.
    Example:
      iex> defmodule BubbleGum do
      ...>    use Syncable, name: __MODULE__, model: [:flavors, :brands]
      ...> end
      iex> BubbleGum.create!(%{"flavors" => ["mint", "berry"],
      ..>  "brands" => ["BigRed"]})
           {:ok, %BubbleGum{flavors: ["mint", "berry"], brands:  ["BigRed"]}}
  """
  use Amnesia

  @doc """
    Builds a syncable
  """
  @lint false # ABC and CC size is way to big
  defmacro syncable(module, api_resource, model, options \\ []) do
    {:__aliases__, _, [thing]} = module
    IO.puts "Defining syncable: #{inspect thing}, with keys: #{inspect model}"
    quote do
      singular = Keyword.get(unquote(options), :singular, false)
      diff = Keyword.get(unquote(options), :diff, false)
      deftable unquote(module)
      deftable unquote(module), unquote(model), type: :ordered_set do
        @moduledoc """
          A #{unquote(module)} from the API.
          \nRequires: #{inspect unquote(model)}
        """

        # TODO(Connor) something better for this???
        @type t :: struct

        # if we want the diff manager, build it here.
        if diff do
          defmodule Diff do
            @moduledoc """
              Diff manager for #{unquote(module)} objects
              Gets updates from Amnesia, and if there is a difference
              sends an event to the Sync EventHandler
            """

            require Logger
            alias Farmbot.Sync.EventManager, as: EM

            @typedoc """
              State of the #{unquote(module)} differ
            """
            @type state :: %{set: MapSet.t}

            @doc """
              Starts the #{unquote(module)} diff module
            """
            @spec start_link :: {:ok, pid}
            def start_link do
              GenServer.start_link(m(), [], name: m())
            end

            @doc false
            @spec init([]) :: {:ok, state}
            def init([]) do
              {:ok, %{set: MapSet.new()}}
            end

            @spec get_state :: state
            def get_state, do: call(:get_state)

            @doc false
            def terminate(_reason, _state) do
              Logger.debug "#{unquote(module)} differ died"
            end

            # HANDLE_CALL
            def handle_call(:get_state, _, state), do: {:reply, state, state}

            # HANDLE_CAST
            def handle_cast({:register, object_list}, state) when is_list(object_list) do
              # new_state = register(state, object_list)
              new_set = MapSet.new(object_list)
              if MapSet.equal?(state.set, new_set) do
                {:noreply, state}
              else
                diff = MapSet.difference(new_set, state.set)
                GenEvent.notify(EM, {unquote(module), diff})
                {:noreply, %{state | set: new_set}}
              end
            end

            def handle_cast({:register, object}, state) do
              # TODO(Connor) fix singular object registeration
              {:crash, :me}
            end

            @spec register(state, [struct]) :: state
            defp register(state, object_list) do
              new_set = MapSet.new(object_list)
              %{state | setA: state.setB, setB: new_set}
            end

            @spec call(any, integer) :: any
            defp call(thing, to \\ 5000), do: GenServer.call(m(), thing, to)

            @spec m :: atom
            def m, do: Module.concat(unquote(module), "Diff")
          end
        # IF DIFF
        end

        @timeout 20_000

        # Throw this at the bottom so if the user definves a mutation
        # They wont need to account for all keys.
        def mutate(_k, v), do: {:ok, v}

        defp handle_http({:ok, %{body: b, status_code: 200}}), do: {:ok, b}
        defp handle_http({:ok, %{status_code: code}}), do: {:error, code}
        defp handle_http({:error, %{reason: reason}}), do: {:error, reason}
        defp handle_http({:error, reason}), do: {:error, reason}
        defp handle_http(err), do: err

        @spec maybe_diff(struct | [struct]) :: :ok
        if diff do
          defp maybe_diff(object_or_objects) do
            GenServer.cast(unquote(module).Diff, {:register, object_or_objects})
          end
        else
          defp maybe_diff(_), do: :ok
        end # IF DIFF

        @doc """
          Enter a singular or list of #{unquote(module)} into the DB
        """
        def enter_into_db(list_or_object)
        def enter_into_db(list_of_objects) when is_list(list_of_objects) do
          stuff = Amnesia.transaction do
            list_of_objects
            |> Enum.map(&unquote(module).write(&1))
          end
          maybe_diff(stuff)
          {:ok, stuff}
        end

        def enter_into_db(object) do
          stuff = Amnesia.transaction do
            unquote(module).write(object)
          end
          maybe_diff(stuff)
          {:ok, stuff}
        end

        @doc """
          Same as `enter_into_db/1` but will raise errors if
          problems are encountered.
        """
        def enter_into_db!(list_or_object)
        def enter_into_db!(list_of_objects) when is_list(list_of_objects) do
          stuff = Amnesia.transaction do
            list_of_objects
            |> Enum.map(&unquote(module).write(&1))
          end
          maybe_diff(stuff)
          stuff
        end

        def enter_into_db!(object) do
          stuff = Amnesia.transaction do
            unquote(module).write!(object)
          end
          maybe_diff(stuff)
        end

        if singular do
          @doc """
            Fetch all #{unquote(module)}s from the API
          """
          def fetch! do
            Farmbot.HTTP.get!(unquote(api_resource), [],
              [recv_timeout: @timeout]).body
            |> Poison.decode!(as: %unquote(module){})
            |> enter_into_db!
          end

          @doc """
            Same as fetch! but will not raise errors
          """
          def fetch do
            resp =
              unquote(api_resource)
              |> Farmbot.HTTP.get([], [recv_timeout: @timeout])
              |> handle_http
            with {:ok, body} <- resp,
                 {:ok, json} <- Poison.decode(body, as: %unquote(module){}),
            do: enter_into_db(json)
          end

        else # IF NOT SINGULAR
          @doc """
            Fetch all #{unquote(module)}s from the API Will raise if
            errors are encountered.
          """
          def fetch! do
            Farmbot.HTTP.get!(unquote(api_resource), [],
              [recv_timeout: @timeout]).body
            |> Poison.decode!(as: [%unquote(module){}])
            |> enter_into_db!
          end

          @doc """
            Same as fetch! but will not raise errors
          """
          def fetch do
            resp =
              unquote(api_resource)
              |> Farmbot.HTTP.get([], [recv_timeout: @timeout])
              |> handle_http
            with {:ok, body} <- resp,
                 {:ok, json} <- Poison.decode(body, as: [%unquote(module){}]),
                 do: enter_into_db(json)
          end
        end

        # Only fetch by id if we are NOT singular
        unless singular do
          @doc """
            Fetch a particular item from the API
          """
          def fetch!(id) do
            "#{unquote(api_resource)}/#{id}"
            |> Farmbot.HTTP.get!([], [recv_timeout: @timeout]).body
            |> Poison.decode!(as: %unquote(module){})
            |> enter_into_db!
          end

          def fetch(id) do
            resp =
              "#{unquote(api_resource)}/#{id}"
              |> Farmbot.HTTP.get([], [recv_timeout: @timeout])
              |> handle_http
            with {:ok, body} <- resp,
                 {:ok, json} <- Poison.decode(body, as: %unquote(module){}),
            do: enter_into_db(json)
          end

        end # unless singular
      end
    end
  end

end
