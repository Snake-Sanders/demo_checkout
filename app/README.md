# App

**Checkout module for a shopping cart**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `app` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:app, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/app>.

## Implementation notes

### Price list file

The default list of prices is stored in a JSON file under `./config/prices.json`. To change this price list, you can create a new JSON file and change the directory path in `runtimes.exs`. Note that there is no need for recompile since this file is loaded at runtime).

The JSON file is loaded after the `init` function, in `handle_continue`. It is recommended not to put slow tasks in the `init` function.

Although it would be much easier to handle the keys in the JSON price list with atoms instead of strings, there is a limitation when using the function: `Poison.Parser.parse!(content, %{keys: :atoms!})`, it is not recommended to convert keys to atoms because atoms are not garbage collected and the list of products can be big. The product `code` is always different.

### Price discount rules

When the list of products gets bigger it is important to consider that the rules for price discount should be mapped as a list of rules, where each rule `has many` (a list of) items to which applies. Currently, the mapping is done as a product `has one` discount.

The default discount rules are:

```elixir
%{
  "VOUCHER" => "2-for-1",
  "TSHIRT" => "bulk-of-3"
}
```

### GenServer

https://elixir-lang.org/downloads/cheatsheets/gen-server.pdf
