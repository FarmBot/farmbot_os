defmodule Farmbot.Farmware do
  @moduledoc """
    Farmware Data Type
  """

  defmodule Meta do
    @moduledoc """
      Stuff on the Manifest we dont really care about that much.
    """

    defstruct [
      :author,
      :language,
      :description,
      :version,
      :min_os_version_major,
      :zip
    ]

    @typedoc "Various garbage we don't care that much about."
    @type t :: %__MODULE__{
      min_os_version_major: binary,
      description:          binary,
      language:             binary,
      version:              binary,
      author:               binary,
      zip:                  binary
    }

    defimpl Inspect, for: __MODULE__ do
      def inspect(thing, _) do
        "#FarmwareMeta<#{thing.description}>"
      end
    end
  end

  defstruct [
    :executable,
    :uuid,
    :name,
    :meta,
    :args,
    :url,
  ]

  @typedoc false
  @type uuid :: binary

  @typedoc """
    The url used to get updates, reinstall, etc.
  """
  @type url :: binary

  @typedoc "Farmware Struct"
  @type t :: %__MODULE__{
    executable: binary,
    uuid:       uuid,
    name:       binary,
    url:        url,
    args:       [binary],
    meta:       Meta.t
  }

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{name: name}, _), do: "#Farmware<#{name}>"
    def inspect(_thing, _), do: "#Farmware<:invalid>"
  end

  @doc """
    Creates a new Farmware Struct
  """
  def new(%{
    "package" => name,
    "language" => language,
    "description" => description,
    "author" => author,
    "version" => version,
    "min_os_version_major" => min_os_version_major,
    "url" => url,
    "zip" => zip,
    "executable" => exe,
    "args" => args
    }) do
    %__MODULE__{
      executable: exe,
      uuid:       Nerves.Lib.UUID.generate(),
      args:       args,
      name:       name,
      url:        url,
      meta: %Meta{
        min_os_version_major: min_os_version_major ,
        description:          description,
        language:             language,
        version:              version,
        author:               author,
        zip:                  zip
      },
    }
  end
end
