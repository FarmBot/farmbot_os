defmodule Farmbot.Farmware do
  @moduledoc "Farmware is Farmbot's plugin system."

  defmodule Meta do
    @moduledoc "Metadata about a Farmware."

    defstruct [:author,:language,:description]
  end

  defstruct [
    :name,
    :version,
    :min_os_version_major,
    :url,
    :zip,
    :executable,
    :args,
    :config,
    :meta,
  ]

  @doc "Lookup a farmware by it's name."
  def lookup(name, version \\ nil) do
    dir = Farmbot.Farmware.Installer.install_root_path
    with {:ok, all_installed} <- File.ls(dir),
         true <- name in all_installed,
         {:ok, versions} <- File.ls(Path.join(dir, name))
    do
      [newest | _] = Enum.sort(versions, fn(ver_a, ver_b) ->
        case Version.compare(ver_a, ver_b) do
          :eq -> true
          :gt -> true
          :lt -> false
        end
      end)
      to_fetch = (version || newest) |> Version.parse!()
      if "#{to_fetch}" in versions do
        mani_path = Path.join(Farmbot.Farmware.Installer.install_path(name, to_fetch), "manifest.json")
        File.read!(mani_path) |> Poison.decode! |> new()
      else
        {:error, :no_version}
      end
    else
      false -> {:error, :not_installed}
      {:error, _} = err -> err
    end
  end

  @doc "Creates a new Farmware Struct"
  def new(map) do
    with {:ok, name}    <- extract_name(map),
         {:ok, version} <- extract_version(map),
         {:ok, os_req}  <- extract_os_requirement(map),
         {:ok, url}     <- extract_url(map),
         {:ok, zip}     <- extract_zip(map),
         {:ok, exe}     <- extract_exe(map),
         {:ok, args}    <- extract_args(map),
         {:ok, config}  <- extract_config(map),
         {:ok, meta}    <- extract_meta(map)
    do
      res = struct(__MODULE__, [name: name,
                                version: version,
                                min_os_version_major: os_req,
                                url: url,
                                zip: zip,
                                executable: exe,
                                args: args,
                                config: config,
                                meta: meta])
      {:ok, res}
    else
      err -> err
    end
  end

  defp extract_name(%{"package" => name}) when is_binary(name), do: {:ok, name}
  defp extract_name(_), do: {:error, "bad or missing farmware name"}

  defp extract_version(%{"version" => version}) do
    case Version.parse(version) do
      {:ok, _} = res -> res
      :error -> {:error, "Could not parse version."}
    end
  end

  defp extract_version(_), do: {:error, "bad or missing farmware version"}

  defp extract_os_requirement(%{"min_os_version_major" => num}) when is_number(num) do
    {:ok, num}
  end

  defp extract_os_requirement(_), do: {:error, "bad or missing os requirement"}

  defp extract_zip(%{"zip" => zip}) when is_binary(zip), do: {:ok, zip}
  defp extract_zip(_), do: {:error, "bad or missing farmware zip url"}

  defp extract_url(%{"url" => url}) when is_binary(url), do: {:ok, url}
  defp extract_url(_), do: {:error, "bad or missing farmware url"}

  defp extract_exe(%{"executable" => exe}) when is_binary(exe) do
    case System.find_executable(exe) do
      nil -> {:error, "#{exe} is not installed"}
      path -> {:ok, path}
    end
  end

  defp extract_exe(_), do: {:error, "bad or missing farmware executable"}

  defp extract_args(%{"args" => args}) when is_list(args) do
    if Enum.all?(args, &is_binary(&1)) do
      {:ok, args}
    else
      {:error, "invalid args"}
    end
  end

  defp extract_args(_), do: {:error, "bad or missing farmware args"}

  defp extract_config(map) do
    {:ok, Map.get(map, "config", [])}
  end

  defp extract_meta(map) do
    desc = Map.get(map, "description", "no description provided.")
    lan  = Map.get(map, "language", "no language provided.")
    auth = Map.get(map, "author", "no author provided")
    {:ok, struct(Meta, [description: desc, language: lan, author: auth])}
  end

end
