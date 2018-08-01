# CeleryScript
CeleryScript is an AST definition of commands, rpcs, and functions that
can all be executed by Farmbot. The basic syntax is as follows:

```elixir
%{
  kind: :some_command,
  args: %{non_order_arg1: 1, non_order_arg2: "data"},
  body: []
}
```

Note the three main fields: `kind`, `args` and `body`.
There is also another field `comment` that is optional. While technically
optional, `body` should be supplied when working with any and all modules
in this project.

## kind
`kind` is the identifier for a command. Examples include:
* `move_absolute`
* `sync`
* `read_status`
* `wait`

Each `kind` will have it's own set of rules for execution. These rules will
define what is required inside of both `args` and `body`.

## args
`args` is arguments to be passed to `kind`. Each `kind` defines it's own
set of optional and required `args`. Args can any of the following types:
* `number`
* `string` (with possible enum types)
* `boolean`
* another AST.

in the case of another AST, that AST will likely need to be evaluated before
executing the parent AST. Examples of `args` include:
* `x`
* `y`
* `z`
* `location`
* `milliseconds`

## body
`body` is the only way a `list` or `array` type is aloud in CeleryScript.
It may only contain _more CeleryScript nodes_. This is useful for
enumeration, scripting looping etc. Here's a syntacticly correct example:
```elixir
%{
  kind: :script,
  args: %{},
  body: [
    %{kind: :command, args: %{x: 1}, body: []}
    %{kind: :command, args: %{x: 2}, body: []}
    %{kind: :command, args: %{x: 3}, body: []}
  ]
}
```

Note there is nesting limit for CeleryScript body nodes, and nodes can
even be self referential. Example:
```elixir
%{
  kind: :self_referencing_script,
  args: %{id: 1},
  body: [
    %{kind: :execute_self_referencing_script, args: %{id: 1}, body: []}
  ]
}
```
