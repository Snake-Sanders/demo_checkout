# App.Checkout

**Checkout module for a demo shopping cart in Elixir**

## Configuration

To modify the product price list, use the default list JSON file as a template 
and create a copy file. The default file is `./config/prices.json`.
The path of the custom price list file shall be set in the environment variable 
`prices_json_path` in the file `./config/runtime.exs`.

## Example

The discount rule set can be passed as a parameter to the constructor.

```Elixir
iex> discounts = ["2-for-1"]
iex> co = Checkout.new(discounts)
iex> co = Checkout.scan(co, "VOUCHER")
iex> co = Checkout.scan(co, "VOUCHER")
iex> Checkout.total(co)         
5.0
```

The currently available discount rules are: 

- `"2-for-1"` 
- `"3-for-1"` 
- `"5-for-2"` 
- `"bulk-of-3"`.

## Implementation notes

### External Interfaces

The required interfaces are `new`, `scan` and `total`, provided by the module `Checkout`.

### Useful future interfaces

It would be useful to expose a set of interfaces that allows the user to:

 - Remove an item from the cart.
 - Clear all the items in the cart.
 - Add multiple units for a single item at once.
 - Inspect the content of the cart.
 - Display items with full price and items with discount price and percentage. 

These interfaces above are left out to avoid adding extra complexity and stick 
to the time budget.

### Price list file

**JSON files**

The JSON file is loaded after the `init` function, in `handle_continue`. This is done as part of the general recommendation to not put slow tasks in the `init` function.

Although it would be much easier to handle the atom keys in the JSON price list instead of strings, there is a limitation when using the function: 

`Poison.Parser.parse!(content, %{keys: :atoms!})`

It is not recommended to convert keys to atoms because atoms are not garbage collected and the list of products can get big. The product `code` is always different.
