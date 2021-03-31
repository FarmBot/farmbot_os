Elixir UUID
===========

[![hex.pm version](https://img.shields.io/hexpm/v/uuid.svg?style=flat)](https://hex.pm/packages/uuid)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/uuid.svg?style=flat)](https://hex.pm/packages/uuid)
[![travis.ci build status](https://img.shields.io/travis/zyro/elixir-uuid.svg?style=flat)](https://travis-ci.org/zyro/elixir-uuid)

UUID generator and utilities for [Elixir](http://elixir-lang.org/). See [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt).

### Installation

The latest version is `1.1.8` and requires Elixir `~> 1.0`. New releases may change this minimum compatible version depending on breaking language changes. The [changelog](https://github.com/zyro/elixir-uuid/blob/master/CHANGELOG.md) lists every available release and its corresponding language version requirement.

Releases are published through [hex.pm](https://hex.pm/packages/uuid). Add as a dependency in your `mix.exs` file:
```elixir
defp deps do
  [ { :uuid, "~> 1.1" } ]
end
```

### UUID v1

Generated using a combination of time since the west adopted the gregorian calendar and the node id MAC address.

```elixir
iex> UUID.uuid1()
"5976423a-ee35-11e3-8569-14109ff1a304"
```

### UUID v3

Generated using the MD5 hash of a name and either a namespace atom or an existing UUID. Valid namespaces are: `:dns`, `:url`, `:oid`, `:x500`, `:nil`.

```elixir
iex> UUID.uuid3(:dns, "my.domain.com")
"03bf0706-b7e9-33b8-aee5-c6142a816478"

iex> UUID.uuid3("5976423a-ee35-11e3-8569-14109ff1a304", "my.domain.com")
"0609d667-944c-3c2d-9d09-18af5c58c8fb"
```

### UUID v4

Generated based on pseudo-random bytes.

```elixir
iex> UUID.uuid4()
"fcfe5f21-8a08-4c9a-9f97-29d2fd6a27b9"
```

### UUID v5

Generated using the SHA1 hash of a name and either a namespace atom or an existing UUID. Valid namespaces are: `:dns`, `:url`, `:oid`, `:x500`, `:nil`.

```elixir
iex> UUID.uuid5(:dns, "my.domain.com")
"016c25fd-70e0-56fe-9d1a-56e80fa20b82"

iex> UUID.uuid5("fcfe5f21-8a08-4c9a-9f97-29d2fd6a27b9", "my.domain.com")
"b8e85535-761a-586f-9c04-0fb0df2cbe84"
```

### Formatting

All UUID generator functions have an optional format parameter as the last argument.

Possible values: `:default`, `:hex`, `:urn`. Default value is `:default` and can be omitted.

`:default` is a standard UUID representation:
```elixir
iex> UUID.uuid1()
"3c69679f-774b-4fb1-80c1-7b29c6e7d0a0"

iex> UUID.uuid4(:default)
"3c69679f-774b-4fb1-80c1-7b29c6e7d0a0"

iex> UUID.uuid3(:dns, "my.domain.com")
"03bf0706-b7e9-33b8-aee5-c6142a816478"

iex> UUID.uuid5(:dns, "my.domain.com", :default)
"016c25fd-70e0-56fe-9d1a-56e80fa20b82"
```

`:hex` is a valid hex string, corresponding to the standard UUID without the `-` (dash) characters:
```elixir
iex> UUID.uuid4(:hex)
"19be859d0c1f4a7f95ddced995037350"

iex> UUID.uuid4(:weak, :hex)
"ebeff765ddc843e486c287fb668d5d37"
```

`:urn` is a standard UUID representation prefixed with the UUID URN:
```elixir
iex> UUID.uuid1(:urn)
"urn:uuid:b7483bde-ee35-11e3-8daa-14109ff1a304"
```

### Utility functions

Use `UUID.info/1` and `UUID.info!/1` to get a [keyword list](http://elixir-lang.org/getting_started/7.html#toc_1) containing information about the given UUID. `UUID.info/1` returns a tuple of `{:ok, info}` for valid cases or `{:error, reason}` if the argument is not a UUID string. `UUID.info!/1` directly returns the info keyword list when successful or raises an `ArgumentError` for error cases.
```elixir
iex> UUID.info!("870df8e8-3107-4487-8316-81e089b8c2cf")
[uuid: "870df8e8-3107-4487-8316-81e089b8c2cf",
 binary: <<135, 13, 248, 232, 49, 7, 68, 135, 131, 22, 129, 224, 137, 184, 194, 207>>,
 type: :default,
 version: 4,
 variant: :rfc4122]

iex> UUID.info!("8ea1513df8a14dea9bea6b8f4b5b6e73")
[uuid: "8ea1513df8a14dea9bea6b8f4b5b6e73",
 binary: <<142, 161, 81, 61, 248, 161, 77, 234, 155, 234, 107, 143, 75, 91, 110, 115>>,
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

Use `UUID.string_to_binary!/1` to convert a valid UUID string to its raw binary equivalent. An `ArgumentError` is raised if the argument is not a valid UUID string.
```elixir
iex> UUID.string_to_binary!("870df8e8-3107-4487-8316-81e089b8c2cf")
<<135, 13, 248, 232, 49, 7, 68, 135, 131,
            22, 129, 224, 137, 184, 194, 207>>

iex> UUID.string_to_binary!("8ea1513df8a14dea9bea6b8f4b5b6e73")
<<142, 161, 81, 61, 248, 161, 77, 234, 155,
            234, 107, 143, 75, 91, 110, 115>>


iex> UUID.string_to_binary!("urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304")
<<239, 27, 26, 40, 238, 52, 17, 227, 136,
            19, 20, 16, 159, 241, 163, 4>>
```

Use `UUID.binary_to_string!/2` to convert valid UUID binary data to a String representation, with an optional format similar to the generator functions above. An `ArgumentError` is raised if the argument is not valid UUID binary data.
```elixir
iex> UUID.binary_to_string!(<<135, 13, 248, 232, 49, 7, 68, 135, 131,
            22, 129, 224, 137, 184, 194, 207>>)
"870df8e8-3107-4487-8316-81e089b8c2cf"

iex> UUID.binary_to_string!(<<142, 161, 81, 61, 248, 161, 77, 234, 155,
            234, 107, 143, 75, 91, 110, 115>>, :hex)
"8ea1513df8a14dea9bea6b8f4b5b6e73"

iex> UUID.binary_to_string!(<<239, 27, 26, 40, 238, 52, 17, 227, 136,
            19, 20, 16, 159, 241, 163, 4>>, :urn)
"urn:uuid:ef1b1a28-ee34-11e3-8813-14109ff1a304"
```

### Attribution

Some code ported from [avtobiff/erlang-uuid](https://github.com/avtobiff/erlang-uuid).

Some helper functions from [rjsamson/hexate](https://github.com/rjsamson/hexate).

### License

```
Copyright 2014-2016 Andrei Mihu

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
