defmodule Farmbot.Farmware do
  @moduledoc """
    Farmware Data Type
  """
  alias Farmbot.Farmware.Installer

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
      :zip,
    ]

    @typedoc "Various garbage we don't care that much about."
    @type t :: %__MODULE__{
      min_os_version_major: binary,
      description:          binary,
      language:             binary,
      version:              binary,
      author:               binary,
      zip:                  binary,
    }

    defimpl Inspect, for: __MODULE__ do
      def inspect(thing, _) do
        "#FarmwareMeta<#{thing.description}>"
      end
    end
  end

  defstruct [
    :executable,
    :name,
    :meta,
    :args,
    :url,
    :path,
    :config
  ]

  @typedoc """
    The url used to get updates, reinstall, etc.
  """
  @type url :: binary

  @typedoc "Farmware name"
  @type name :: binary

  @typedoc "Farmware Struct"
  @type t :: %__MODULE__{
    executable: binary,
    name:       name,
    url:        url,
    args:       [binary],
    meta:       Meta.t,
    path:       Path.t
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
    "args" => args,
    } = new) do
    %__MODULE__{
      executable: exe,
      args:       args,
      name:       name,
      url:        url,
      path:       "#{Installer.package_path()}/#{name}",
      config:     new["config"] || [],
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
