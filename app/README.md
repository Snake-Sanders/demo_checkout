# App.Checkout

**Checkout module for a demo shopping cart in Elixir**

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

Documentation can be generated with [ExDoc]
(https://github.com/elixir-lang/ex_doc) and published on 
[HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/app>.

## Configuration

To modify the product price list, use the default list JSON file as a template 
and create a copy file. The default file is `./config/prices.json`.
The path of the custom price list file shall be set in the environment variable 
`prices_json_path` in the file `./config/runtime.exs`.

## Example

The discount rule set can be passed as a parameter to the constructor.

```Elixir
iex> alias App.Checkout, as: Co
iex> discounts = %{ "MUG" => "2-for-1"}
iex> {:ok, pid} = Co.new(discounts)
iex> Co.scan(pid, "MUG")
:ok
iex> Co.scan(pid, "MUG")
:ok
iex> Co.total(pid)         
7.50
```

**Note**: The alias `Co` is no longer needed since this alias is already set automatically in `.iex.exs`.

The currently available discount rules are `"2-for-1"` and `"bulk-of-3"`.

## Implementation notes

### External Interfaces

The required interfaces are `new`, `scan` and `total`, however, there are other 
interfaces exposed within the same module. These interfaces could be private but
are needed to unit test coverage. 

A better approach is to extract them to another file, but a directory 
restructuration could be done a bit later when more requirements are defined and
after this unit was reviewed.

### Useful future interfaces

It would be useful to expose a set of interfaces that allows the user to:

 - Remove an item from the cart.
 - Add multiple units for a single item.
 - Clear items in the cart.
 - Inspect the content of the cart.
 - Display items with full price and items with discount price and percentage. 

These interfaces are left out to avoid adding extra complexity and stick to 
the time budget.

### Price list file

**JSON files**
The JSON file is loaded after the `init` function, in `handle_continue`. It is
recommended not to put slow tasks in the `init` function.

Although it would be much easier to handle the keys in the JSON price list with 
atoms instead of strings, there is a limitation when using the function: 
`Poison.Parser.parse!(content, %{keys: :atoms!})`, it is not recommended to 
convert keys to atoms because atoms are not garbage collected and the list of 
products can be big. The product `code` is always different.

**Testing**
The test unit uses a hardcoded price list defined within the Checkout module.
A better approach is to use dependency injection, but for that, the 
initialization interface has to be clearly defined.

### Price discount rules

**Data relationship**
When the list of products gets bigger it is important to consider that the rules
for price discount should be mapped as a list of rules, where each rule 
`has many` (a list of) items to which applies. Currently, the mapping is done as 
a product `has one` discount.

**Error Handling**
If the rules passed to the initialization function contains invalid rules, these
are ignored. It would be convenient to have a checker that notifies the user 
about any error.

The default discount rules are:

```elixir
%{
  "VOUCHER" => "2-for-1",
  "TSHIRT" => "bulk-of-3"
}
```

### GenServer

https://elixir-lang.org/downloads/cheatsheets/gen-server.pdf
