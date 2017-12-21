defmodule Farmbot.HTTP.Adapter do
  @moduledoc "Behaviour for a Farmbot HTTP adapter implementation."
  alias Farmbot.HTTP.Response

  @typedoc "Adapter pid."
  @type adapter :: pid

  @typedoc "HTTP method."
  @type method :: :get | :put | :post | :update

  @typedoc "HTTP url. Must be fully formatted."
  @type url :: binary

  @typedoc "HTTP request payload."
  @type body :: binary

  @typedoc "HTTP request header."
  @type headers :: [{binary, binary}]

  @typedoc "Options to the underlying http adapter."
  @type opts :: Keyword.t()

  @typedoc """
  Callback for progress of a downloaded file.
  Arg 1 should be the the downloaded bytes.
  Arg 2 should be the total number of bytes, nil, or the atom :complete
  """
  @type progress_callback :: (number, number | nil | :complete -> any)
  @type stream_fun :: (number, binary -> any)

  @typedoc "A json serializable map of meta data about an upload."
  @type upload_meta :: map

  @doc "HTTP Request."
  @callback request(adapter, method, url, body, headers, opts) ::
              {:ok, Response.t()} | {:error, term}

  @doc "Download a file to the Filesystem."
  @callback download_file(adapter,
                          url,
                          Path.t(),
                          progress_callback,
                          body, headers,
                          stream_fun) :: {:ok, Path.t()} | {:error, term}

  @doc "Upload a file."
  @callback upload_file(adapter, Path.t(), upload_meta) :: :ok | {:error, term}

  @doc "Start the adapter."
  @callback start_link() :: {:ok, adapter}
end
