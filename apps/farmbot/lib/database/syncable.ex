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
  defmacro syncable(module, api_resource, model, options \\ []) do
    {:__aliases__, _, [thing]} = module
    IO.puts "Defining syncable: #{inspect thing}, with keys: #{inspect model}"
    quote do
      singular = Keyword.get(unquote(options), :singular, false)
      deftable unquote(module)
      deftable unquote(module), unquote(model), type: :bag do
        @moduledoc """
          A #{unquote(module)} from the API.
          \nRequires: #{inspect unquote(model)}
        """

        # Throw this at the bottom so if the user definves a mutation
        # They wont need to account for all keys.
        def mutate(_k, v), do: {:ok, v}

        defp handle_http({:ok, %{body: b, status_code: 200}}), do: {:ok, b}
        defp handle_http({:ok, %{status_code: code}}), do: {:error, code}
        defp handle_http({:error, %{reason: reason}}), do: {:error, reason}
        defp handle_http({:error, reason}), do: {:error, reason}
        defp handle_http(err), do: err

        if singular do
          @doc """
            Fetch all #{unquote(module)}s from the API
          """
          def fetch! do
            Farmbot.HTTP.get!(unquote(api_resource)).body
            |> Poison.decode!(as: %unquote(module){})
          end

          @doc """
            Same as fetch! but will not raise errors
          """
          def fetch do
            resp =
              unquote(api_resource)
              |> Farmbot.HTTP.get
              |> handle_http
            with {:ok, body} <- resp do
              Poison.decode(body, as: %unquote(module){})
            end
          end

        else # IF NOT SINGULAR
          @doc """
            Fetch all #{unquote(module)}s from the API Will raise if
            errors are encountered.
          """
          def fetch! do
            Farmbot.HTTP.get!(unquote(api_resource)).body
            |> Poison.decode!(as: [%unquote(module){}])
          end

          @doc """
            Same as fetch! but will not raise errors
          """
          def fetch do
            resp =
              unquote(api_resource)
              |> Farmbot.HTTP.get
              |> handle_http
            with {:ok, body} <- resp do
              Poison.decode(body, as: [%unquote(module){}])
            end
          end
        end

        # Only fetch by id if we are NOT singular
        unless singular do
          @doc """
            Fetch a particular item from the API
          """
          def fetch!(id) do
            Farmbot.HTTP.get!("#{unquote(api_resource)}/#{id}").body
            |> Poison.decode!(as: %unquote(module){})
          end

          def fetch(id) do
            resp =
              Farmbot.HTTP.get("#{unquote(api_resource)}/#{id}")
              |> handle_http
            with {:ok, body} <- resp do
              Poison.decode(body, as: %unquote(module){})
            end
          end

        end # unless singular
      end
    end
  end

end
