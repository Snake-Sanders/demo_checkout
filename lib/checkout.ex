defmodule Checkout do
  alias Checkout.Cart
  alias Checkout.Prices
  alias Checkout.Rules
  alias Checkout.Discounts

  defstruct cart: %{}, discounts: [], prices: %{}

  @doc """
  Creates a new instance of Checkout.

  Receives a set of pricing rules as parameter. A pricing rule can applies
  `discounts` to multiple products.

  Additionally, it creates a shopping cart as an empty list of items.

  The function also loads the product's `prices` list from a JSON file located in
  `./config/prices.json`.
  The product list is defined as a collection of items with the attributes:
  `code`, `description` and `price`.

  ## Parameters

  - pricing_rules: is a map of pricing rules and products.
    The pricing rule is a string indicating the type of discount to be applied.
    The discounts can be:
    `x-for-y`, example: 2-for-1, 3-for-1, 5-for-2 and so on.
    `bulk-x`, example: bulk-3, bulk-6, etc.

  return:
    %Checkout{}

  ## Example:

    iex> pricing_rules = ["2-for-1"]
    iex> Checkout.new(pricing_rules)
    %Checkout{
        cart: %{},
        discounts: %{"x-for" => {2, 1}},
        prices: %{
          "MUG" => %{"name" => "Coffee Mug", "price" => 7.5},
          "TSHIRT" => %{"name" => "T-Shirt", "price" => 20.0},
          "VOUCHER" => %{"name" => "Voucher", "price" => 5.0}
        }
      }
  """
  def new(pricing_rules) when is_list(pricing_rules) do
    with {:ok, rules} <- Rules.sanitize_rules(pricing_rules),
         {:ok, prices} <- Prices.load_prices() do
      %Checkout{
        cart: %{},
        discounts: rules,
        prices: prices
      }
    else
      {:error, reason} ->
        # TODO: use Logger
        puts_log(reason)
        :error
    end
  end

  @doc """
  Adds an item to the list.

  Adds an item to the shopping cart. If the item is already in the cart,
  the item's quantity is increased.
  If the item is not defined in the price list the item is ignored and a log
  message is displayed.

  ## Parameter

  - cart: shopping cart
  - item_code: The item code to add to the cart.

  ## Example:

    iex> pricing_rules = []
    iex> co = Checkout.new(pricing_rules)
    iex> co.cart
    %{}
    iex> co = Checkout.scan(co, "MUG")
    iex> co = Checkout.scan(co, "MUG")
    iex> co.cart
    %{"MUG" => 2}
  """
  def scan(%Checkout{} = checkout, item_code) when is_bitstring(item_code) do
    # searches the item code in the price list
    case checkout.prices[item_code] do
      nil ->
        puts_log("The item '#{item_code}' is not a valid product")
        checkout

      _item ->
        new_cart = Cart.add_item(checkout.cart, item_code)
        put_in(checkout.cart, new_cart)
    end
  end

  @doc """
  Calculates the total price of the items in the cart.

  First is calculated the discount based on the quanity of a product.
  Then the discount is applied when calculating product final price per unit.

  Returns the total price of the items in the cart taking in consideration the
  discount rules.

    ## Example:

    iex> pricing_rules = []
    iex> co = Checkout.new(pricing_rules)
    iex> co = Checkout.scan(co, "MUG")
    iex> Checkout.total(co)
    7.5
  """
  # def total(%Checkout{} = checkout) do
  def total(%Checkout{cart: cart, prices: prices, discounts: discounts}) do
    cart
    |> Discounts.calculate_discount(discounts)
    |> Cart.calculate_price(prices)
  end

  # Prints a log line to the terminal.
  # The log is ignored in test environment.
  defp puts_log(text) do
    IO.puts(text)
  end
end
