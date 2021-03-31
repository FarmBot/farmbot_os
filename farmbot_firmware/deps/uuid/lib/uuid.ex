defmodule UUID do
  use Bitwise, only_operators: true
  @moduledoc """
  UUID generator and utilities for [Elixir](http://elixir-lang.org/).
  See [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt).
  """

  @nanosec_intervals_offset 122_192_928_000_000_000 # 15 Oct 1582 to 1 Jan 1970.
  @nanosec_intervals_factor 10 # Microseconds to nanoseconds factor.

  @variant10 2 # Variant, corresponds to variant 1 0 of RFC 4122.
  @uuid_v1 1 # UUID v1 identifier.
  @uuid_v3 3 # UUID v3 identifier.
  @uuid_v4 4 # UUID v4 identifier.
  @uuid_v5 5 # UUID v5 identifier.

  @urn "urn:uuid:" # UUID URN prefix.

  @doc """
  Inspect a UUID and return tuple with `{:ok, result}`, where result is
  information about its 128-bit binary content, type,
  version and variant.

  Timestamp portion is not checked to see if it's in the future, and therefore
  not yet assignable. See "Validation mechanism" in section 3 of
  [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt).

  Will return `{:error, message}` if the given string is not a UUID representation
  in a format like:
  * `"870df8e8-3107-4487-8316-81e089b8c2cf"`
  * `"8ea1513df8a14dea9bea6b8f4b5b6e73"`
  * `"urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304"`

  ## Examples

  ```elixir
  iex> UUID.info("870df8e8-3107-4487-8316-81e089b8c2cf")
  {:ok, [uuid: "870df8e8-3107-4487-8316-81e089b8c2cf",
   binary: <<135, 13, 248, 232, 49, 7, 68, 135, 131, 22, 129, 224, 137, 184, 194, 207>>,
   type: :default,
   version: 4,
   variant: :rfc4122]}

  iex> UUID.info("8ea1513df8a14dea9bea6b8f4b5b6e73")
  {:ok, [uuid: "8ea1513df8a14dea9bea6b8f4b5b6e73",
   binary: <<142, 161, 81, 61, 248, 161, 77, 234, 155,
              234, 107, 143, 75, 91, 110, 115>>,
   type: :hex,
   version: 4,
   variant: :rfc4122]}

  iex> UUID.info("urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304")
  {:ok, [uuid: "urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304",
   binary: <<239, 27, 26, 40, 238, 52, 17, 227, 136, 19, 20, 16, 159, 241, 163, 4>>,
   type: :urn,
   version: 1,
   variant: :rfc4122]}

  iex> UUID.info("12345")
  {:error, "Invalid argument; Not a valid UUID: 12345"}

  ```

  """
  def info(uuid) do
    try do
      {:ok, UUID.info!(uuid)}
    rescue
      e in ArgumentError -> {:error, e.message}
    end
  end

  @doc """
  Inspect a UUID and return information about its 128-bit binary content, type,
  version and variant.

  Timestamp portion is not checked to see if it's in the future, and therefore
  not yet assignable. See "Validation mechanism" in section 3 of
  [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt).

  Will raise an `ArgumentError` if the given string is not a UUID representation
  in a format like:
  * `"870df8e8-3107-4487-8316-81e089b8c2cf"`
  * `"8ea1513df8a14dea9bea6b8f4b5b6e73"`
  * `"urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304"`

  ## Examples

  ```elixir
  iex> UUID.info!("870df8e8-3107-4487-8316-81e089b8c2cf")
  [uuid: "870df8e8-3107-4487-8316-81e089b8c2cf",
   binary: <<135, 13, 248, 232, 49, 7, 68, 135, 131, 22, 129, 224, 137, 184, 194, 207>>,
   type: :default,
   version: 4,
   variant: :rfc4122]

  iex> UUID.info!("8ea1513df8a14dea9bea6b8f4b5b6e73")
  [uuid: "8ea1513df8a14dea9bea6b8f4b5b6e73",
   binary: <<142, 161, 81, 61, 248, 161, 77, 234, 155,
              234, 107, 143, 75, 91, 110, 115>>,
   type: :hex,
   version: 4,
   variant: :rfc4122]

  iex> UUID.info!("urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304")
  [uuid: "urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304",
   binary: <<239, 27, 26, 40, 238, 52, 17, 227, 136, 19, 20, 16, 159, 241, 163, 4>>,
   type: :urn,
   version: 1,
   variant: :rfc4122]

  ```

  """
  def info!(<<uuid::binary>> = uuid_string) do
    {type, <<uuid::128>>} = uuid_string_to_hex_pair(uuid)
    <<_::48, version::4, _::12, v0::1, v1::1, v2::1, _::61>> = <<uuid::128>>
    [uuid: uuid_string,
     binary: <<uuid::128>>,
     type: type,
     version: version,
     variant: variant(<<v0, v1, v2>>)]
  end
  def info!(_) do
    raise ArgumentError, message: "Invalid argument; Expected: String"
  end

  @doc """
  Convert binary UUID data to a string.

  Will raise an ArgumentError if the given binary is not valid UUID data, or
  the format argument is not one of: `:default`, `:hex`, or `:urn`.

  ## Examples

  ```elixir
  iex> UUID.binary_to_string!(<<135, 13, 248, 232, 49, 7, 68, 135,
  ...>        131, 22, 129, 224, 137, 184, 194, 207>>)
  "870df8e8-3107-4487-8316-81e089b8c2cf"

  iex> UUID.binary_to_string!(<<142, 161, 81, 61, 248, 161, 77, 234, 155,
  ...>        234, 107, 143, 75, 91, 110, 115>>, :hex)
  "8ea1513df8a14dea9bea6b8f4b5b6e73"

  iex> UUID.binary_to_string!(<<239, 27, 26, 40, 238, 52, 17, 227, 136,
  ...>        19, 20, 16, 159, 241, 163, 4>>, :urn)
  "urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304"

  ```

  """
  def binary_to_string!(uuid, format \\ :default)
  def binary_to_string!(<<uuid::binary>>, format) do
    uuid_to_string(<<uuid::binary>>, format)
  end
  def binary_to_string!(_, _) do
    raise ArgumentError, message: "Invalid argument; Expected: <<uuid::128>>"
  end

  @doc """
  Convert a UUID string to its binary data equivalent.

  Will raise an ArgumentError if the given string is not a UUID representation
  in a format like:
  * `"870df8e8-3107-4487-8316-81e089b8c2cf"`
  * `"8ea1513df8a14dea9bea6b8f4b5b6e73"`
  * `"urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304"`

  ## Examples

  ```elixir
  iex> UUID.string_to_binary!("870df8e8-3107-4487-8316-81e089b8c2cf")
  <<135, 13, 248, 232, 49, 7, 68, 135, 131, 22, 129, 224, 137, 184, 194, 207>>

  iex> UUID.string_to_binary!("8ea1513df8a14dea9bea6b8f4b5b6e73")
  <<142, 161, 81, 61, 248, 161, 77, 234, 155, 234, 107, 143, 75, 91, 110, 115>>

  iex> UUID.string_to_binary!("urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304")
  <<239, 27, 26, 40, 238, 52, 17, 227, 136, 19, 20, 16, 159, 241, 163, 4>>

  ```

  """
  def string_to_binary!(<<uuid::binary>>) do
    {_type, <<uuid::128>>} = uuid_string_to_hex_pair(uuid)
    <<uuid::128>>
  end
  def string_to_binary!(_) do
    raise ArgumentError, message: "Invalid argument; Expected: String"
  end

  @doc """
  Generate a new UUID v1. This version uses a combination of one or more of:
  unix epoch, random bytes, pid hash, and hardware address.

  ## Examples

  ```elixir
  iex> UUID.uuid1()
  "cdfdaf44-ee35-11e3-846b-14109ff1a304"

  iex> UUID.uuid1(:default)
  "cdfdaf44-ee35-11e3-846b-14109ff1a304"

  iex> UUID.uuid1(:hex)
  "cdfdaf44ee3511e3846b14109ff1a304"

  iex> UUID.uuid1(:urn)
  "urn:uuid:cdfdaf44-ee35-11e3-846b-14109ff1a304"

  ```

  """
  def uuid1(format \\ :default) do
    uuid1(uuid1_clockseq(), uuid1_node(), format)
  end

  @doc """
  Generate a new UUID v1, with an existing clock sequence and node address. This
  version uses a combination of one or more of: unix epoch, random bytes,
  pid hash, and hardware address.

  ## Examples

  ```elixir
  iex> UUID.uuid1()
  "cdfdaf44-ee35-11e3-846b-14109ff1a304"

  iex> UUID.uuid1(:default)
  "cdfdaf44-ee35-11e3-846b-14109ff1a304"

  iex> UUID.uuid1(:hex)
  "cdfdaf44ee3511e3846b14109ff1a304"

  iex> UUID.uuid1(:urn)
  "urn:uuid:cdfdaf44-ee35-11e3-846b-14109ff1a304"

  ```

  """
  def uuid1(clock_seq, node, format \\ :default)
  def uuid1(<<clock_seq::14>>, <<node::48>>, format) do
    <<time_hi::12, time_mid::16, time_low::32>> = uuid1_time()
    <<clock_seq_hi::6, clock_seq_low::8>> = <<clock_seq::14>>
    <<time_low::32, time_mid::16, @uuid_v1::4, time_hi::12, @variant10::2,
      clock_seq_hi::6, clock_seq_low::8, node::48>>
      |> uuid_to_string(format)
  end
  def uuid1(_, _, _) do
    raise ArgumentError, message:
    "Invalid argument; Expected: <<clock_seq::14>>, <<node::48>>"
  end

  @doc """
  Generate a new UUID v3. This version uses an MD5 hash of fixed value (chosen
  based on a namespace atom - see Appendix C of
  [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt) and a name value. Can also be
  given an existing UUID String instead of a namespace atom.

  Accepted arguments are: `:dns`|`:url`|`:oid`|`:x500`|`:nil` OR uuid, String

  ## Examples

  ```elixir
  iex> UUID.uuid3(:dns, "my.domain.com")
  "03bf0706-b7e9-33b8-aee5-c6142a816478"

  iex> UUID.uuid3(:dns, "my.domain.com", :default)
  "03bf0706-b7e9-33b8-aee5-c6142a816478"

  iex> UUID.uuid3(:dns, "my.domain.com", :hex)
  "03bf0706b7e933b8aee5c6142a816478"

  iex> UUID.uuid3(:dns, "my.domain.com", :urn)
  "urn:uuid:03bf0706-b7e9-33b8-aee5-c6142a816478"

  iex> UUID.uuid3("cdfdaf44-ee35-11e3-846b-14109ff1a304", "my.domain.com")
  "8808f33a-3e11-3708-919e-15fba88908db"

  ```

  """
  def uuid3(namespace_or_uuid, name, format \\ :default)
  def uuid3(:dns, <<name::binary>>, format) do
    namebased_uuid(:md5, <<0x6ba7b8109dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid3(:url, <<name::binary>>, format) do
    namebased_uuid(:md5, <<0x6ba7b8119dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid3(:oid, <<name::binary>>, format) do
    namebased_uuid(:md5, <<0x6ba7b8129dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid3(:x500, <<name::binary>>, format) do
    namebased_uuid(:md5, <<0x6ba7b8149dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid3(:nil, <<name::binary>>, format) do
    namebased_uuid(:md5, <<0::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid3(<<uuid::binary>>, <<name::binary>>, format) do
    {_type, <<uuid::128>>} = uuid_string_to_hex_pair(uuid)
    namebased_uuid(:md5, <<uuid::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid3(_, _, _) do
    raise ArgumentError, message:
    "Invalid argument; Expected: :dns|:url|:oid|:x500|:nil OR String, String"
  end

  @doc """
  Generate a new UUID v4. This version uses pseudo-random bytes generated by
  the `crypto` module.

  ## Examples

  ```elixir
  iex> UUID.uuid4()
  "fb49a0ec-d60c-4d20-9264-3b4cfe272106"

  iex> UUID.uuid4(:default)
  "fb49a0ec-d60c-4d20-9264-3b4cfe272106"

  iex> UUID.uuid4(:hex)
  "fb49a0ecd60c4d2092643b4cfe272106"

  iex> UUID.uuid4(:urn)
  "urn:uuid:fb49a0ec-d60c-4d20-9264-3b4cfe272106"
  ```

  """
  def uuid4(), do: uuid4(:default)

  def uuid4(:strong), do: uuid4(:default) # For backwards compatibility.
  def uuid4(:weak),   do: uuid4(:default) # For backwards compatibility.
  def uuid4(format) do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)
    <<u0::48, @uuid_v4::4, u1::12, @variant10::2, u2::62>>
      |> uuid_to_string(format)
  end

  @doc """
  Generate a new UUID v5. This version uses an SHA1 hash of fixed value (chosen
  based on a namespace atom - see Appendix C of
  [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt) and a name value. Can also be
  given an existing UUID String instead of a namespace atom.

  Accepted arguments are: `:dns`|`:url`|`:oid`|`:x500`|`:nil` OR uuid, String

  ## Examples

  ```elixir
  iex> UUID.uuid5(:dns, "my.domain.com")
  "016c25fd-70e0-56fe-9d1a-56e80fa20b82"

  iex> UUID.uuid5(:dns, "my.domain.com", :default)
  "016c25fd-70e0-56fe-9d1a-56e80fa20b82"

  iex> UUID.uuid5(:dns, "my.domain.com", :hex)
  "016c25fd70e056fe9d1a56e80fa20b82"

  iex> UUID.uuid5(:dns, "my.domain.com", :urn)
  "urn:uuid:016c25fd-70e0-56fe-9d1a-56e80fa20b82"

  iex> UUID.uuid5("fb49a0ec-d60c-4d20-9264-3b4cfe272106", "my.domain.com")
  "822cab19-df58-5eb4-98b5-c96c15c76d32"

  ```

  """
  def uuid5(namespace_or_uuid, name, format \\ :default)
  def uuid5(:dns, <<name::binary>>, format) do
    namebased_uuid(:sha1, <<0x6ba7b8109dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid5(:url, <<name::binary>>, format) do
    namebased_uuid(:sha1, <<0x6ba7b8119dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid5(:oid, <<name::binary>>, format) do
    namebased_uuid(:sha1, <<0x6ba7b8129dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid5(:x500, <<name::binary>>, format) do
    namebased_uuid(:sha1, <<0x6ba7b8149dad11d180b400c04fd430c8::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid5(:nil, <<name::binary>>, format) do
    namebased_uuid(:sha1, <<0::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid5(<<uuid::binary>>, <<name::binary>>, format) do
    {_type, <<uuid::128>>} = uuid_string_to_hex_pair(uuid)
    namebased_uuid(:sha1, <<uuid::128, name::binary>>)
      |> uuid_to_string(format)
  end
  def uuid5(_, _, _) do
    raise ArgumentError, message:
    "Invalid argument; Expected: :dns|:url|:oid|:x500|:nil OR String, String"
  end

  #
  # Internal utility functions.
  #

  # Convert UUID bytes to String.
  defp uuid_to_string(<<u0::32, u1::16, u2::16, u3::16, u4::48>>, :default) do
    [binary_to_hex_list(<<u0::32>>), ?-, binary_to_hex_list(<<u1::16>>), ?-,
     binary_to_hex_list(<<u2::16>>), ?-, binary_to_hex_list(<<u3::16>>), ?-,
     binary_to_hex_list(<<u4::48>>)]
      |> IO.iodata_to_binary
  end
  defp uuid_to_string(<<u::128>>, :hex) do
    binary_to_hex_list(<<u::128>>)
      |> IO.iodata_to_binary
  end
  defp uuid_to_string(<<u::128>>, :urn) do
    @urn <> uuid_to_string(<<u::128>>, :default)
  end
  defp uuid_to_string(_u, format) when format in [:default, :hex, :urn] do
    raise ArgumentError, message:
    "Invalid binary data; Expected: <<uuid::128>>"
  end
  defp uuid_to_string(_u, format) do
    raise ArgumentError, message:
    "Invalid format #{format}; Expected: :default|:hex|:urn"
  end

  # Extract the type (:default etc) and pure byte value from a UUID String.
  defp uuid_string_to_hex_pair(<<uuid::binary>>) do
    uuid = String.downcase(uuid)
    {type, hex_str} = case uuid do
      <<u0::64, ?-, u1::32, ?-, u2::32, ?-, u3::32, ?-, u4::96>> ->
        {:default, <<u0::64, u1::32, u2::32, u3::32, u4::96>>}
      <<u::256>> ->
        {:hex, <<u::256>>}
      <<@urn, u0::64, ?-, u1::32, ?-, u2::32, ?-, u3::32, ?-, u4::96>> ->
        {:urn, <<u0::64, u1::32, u2::32, u3::32, u4::96>>}
      _ ->
        raise ArgumentError, message:
          "Invalid argument; Not a valid UUID: #{uuid}"
    end

    try do
      <<hex::128>> = :binary.bin_to_list(hex_str)
        |> hex_str_to_list
        |> IO.iodata_to_binary
      {type, <<hex::128>>}
    catch
      _, _ ->
        raise ArgumentError, message:
          "Invalid argument; Not a valid UUID: #{uuid}"
    end
  end

  # Get unix epoch as a 60-bit timestamp.
  defp uuid1_time() do
    {mega_sec, sec, micro_sec} = :os.timestamp()
    epoch = (mega_sec * 1_000_000_000_000 + sec * 1_000_000 + micro_sec)
    timestamp = @nanosec_intervals_offset + @nanosec_intervals_factor * epoch
    <<timestamp::60>>
  end

  # Generate random clock sequence.
  defp uuid1_clockseq() do
    <<rnd::14, _::2>> = :crypto.strong_rand_bytes(2)
    <<rnd::14>>
  end

  # Get local IEEE 802 (MAC) address, or a random node id if it can't be found.
  defp uuid1_node() do
    {:ok, ifs0} = :inet.getifaddrs()
    uuid1_node(ifs0)
  end

  defp uuid1_node([{_if_name, if_config} | rest]) do
    case :lists.keyfind(:hwaddr, 1, if_config) do
      :false ->
        uuid1_node(rest)
      {:hwaddr, hw_addr} ->
        if length(hw_addr) != 6 or Enum.all?(hw_addr, fn(n) -> n == 0 end) do
          uuid1_node(rest)
        else
          :erlang.list_to_binary(hw_addr)
        end
    end
  end
  defp uuid1_node(_) do
    <<rnd_hi::7, _::1, rnd_low::40>> = :crypto.strong_rand_bytes(6)
    <<rnd_hi::7, 1::1, rnd_low::40>>
  end

  # Generate a hash of the given data.
  defp namebased_uuid(:md5, data) do
    md5 = :crypto.hash(:md5, data)
    compose_namebased_uuid(@uuid_v3, md5)
  end
  defp namebased_uuid(:sha1, data) do
    <<sha1::128, _::32>> = :crypto.hash(:sha, data)
    compose_namebased_uuid(@uuid_v5, <<sha1::128>>)
  end

  # Format the given hash as a UUID.
  defp compose_namebased_uuid(version, hash) do
    <<time_low::32, time_mid::16, _::4, time_hi::12, _::2,
      clock_seq_hi::6, clock_seq_low::8, node::48>> = hash
    <<time_low::32, time_mid::16, version::4, time_hi::12, @variant10::2,
      clock_seq_hi::6, clock_seq_low::8, node::48>>
  end

  # Identify the UUID variant according to section 4.1.1 of RFC 4122.
  defp variant(<<1, 1, 1>>) do
    :reserved_future
  end
  defp variant(<<1, 1, _v>>) do
    :reserved_microsoft
  end
  defp variant(<<1, 0, _v>>) do
    :rfc4122
  end
  defp variant(<<0, _v::2-binary>>) do
    :reserved_ncs
  end
  defp variant(_) do
    raise ArgumentError, message: "Invalid argument; Not valid variant bits"
  end

  # Binary data to list of hex characters.
  defp binary_to_hex_list(binary) do
    :binary.bin_to_list(binary)
      |> list_to_hex_str
  end

  # Hex string to hex character list.
  defp hex_str_to_list([]) do
    []
  end
  defp hex_str_to_list([x, y | tail]) do
    [to_int(x) * 16 + to_int(y) | hex_str_to_list(tail)]
  end

  # List of hex characters to a hex character string.
  defp list_to_hex_str([]) do
    []
  end
  defp list_to_hex_str([head | tail]) do
    to_hex_str(head) ++ list_to_hex_str(tail)
  end

  # Hex character integer to hex string.
  defp to_hex_str(n) when n < 256 do
    [to_hex(div(n, 16)), to_hex(rem(n, 16))]
  end

  # Integer to hex character.
  defp to_hex(i) when i < 10 do
    0 + i + 48
  end
  defp to_hex(i) when i >= 10 and i < 16 do
    ?a + (i - 10)
  end

  # Hex character to integer.
  defp to_int(c) when ?0 <= c and c <= ?9 do
    c - ?0
  end
  defp to_int(c) when ?A <= c and c <= ?F do
    c - ?A + 10
  end
  defp to_int(c) when ?a <= c and c <= ?f do
    c - ?a + 10
  end

end
