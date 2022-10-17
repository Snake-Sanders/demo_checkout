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
are needed for unit test coverage. 

A better approach is to extract these functions to another file, but a directory 
restructuration could be done a bit later when more requirements are defined and
after this unit was reviewed.

### Useful future interfaces

It would be useful to expose a set of interfaces that allows the user to:

 - Remove an item from the cart.
 - Clear all the items in the cart.
 - Add multiple units for a single item at once.
 - Inspect the content of the cart.
 - Display items with full price and items with discount price and percentage. 

These interfaces above are left out to avoid adding extra complexity and stick to 
the time budget.

### Price list file

**JSON files**

The JSON file is loaded after the `init` function, in `handle_continue`. This is done as part of the general recommendation to not put slow tasks in the `init` function.

Although it would be much easier to handle the atom keys in the JSON price list instead of strings, there is a limitation when using the function: 

`Poison.Parser.parse!(content, %{keys: :atoms!})`

It is not recommended to 
convert keys to atoms because atoms are not garbage collected and the list of 
products can get big. The product `code` is always different.

**Testing**

The test unit uses a hardcoded price list defined within the `Checkout` module.
A better approach is to use dependency injection, but for that, the 
initialization interface has to be clearly defined.

When executing the unit testing, it is common to avoid opening files to not slow down the running testing tasks. In this case, the price list is taken directly from the `Checkout` module, instead of reading the JSON file. 
The good thing is that if the JSON file, for some reason, gets modified the tests still pass. However, there are some logic branches that the test unit cannot cover because they are forced by the test environment variable. A good balance can be achieved, but that will depend on how the module evolves.

### Price discount rules

**Data relationship**

When the list of products gets bigger it is important to consider that the rules
for price discount should be mapped as a list of rules, where each rule 
`has many` (a list of) items to which applies. Currently, the mapping is done as 
a product `has one` discount.

**Error Handling**

If the rules passed to the initialization function contains invalid items, these
are ignored. It would be convenient to have a checker that notifies the users 
about any error they might have introduced.

The default discount rules are:

```elixir
%{
  "VOUCHER" => "2-for-1",
  "TSHIRT" => "bulk-of-3"
}
```

### GenServer

Probably the event for adding items to the cart should be done with a sync 
callback `handle_call`, rather than using `handle_cast`. As it is now implemented, 
the user gets a log line in the console. However, the choice will be more 
related to the error handler mechanism required by the consumer of the interface. 

https://elixir-lang.org/downloads/cheatsheets/gen-server.pdf
