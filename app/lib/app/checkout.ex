defmodule App.Checkout do
  use GenServer

  defmodule State do
    defstruct prices: %{}, discounts: %{}, cart: %{}
  end

  def is_test_env(), do: Mix.env() == :test

  # Client interfaces

  @doc """
  The `new` function starts a new Checkout module GenServer.

  The Checkout module initialization loads the default price discount rule set
  defined within this module.
  Alternative a custom set of rules can be passed as argument to the `new`
  function.
  The product list is defined as a collection of items with the attributes:
  code, description and price. This list is loaded from a JSON file located in
  `./config/prices.json`.

  If no parameters are given, the function will load the default discount rules.

  ## Example: Using the default configuration

      iex> alias App.Checkout, as: Co
      iex> {:ok, pid} = Co.new()
      iex> Co.scan(pid, "TSHIRT")
      :ok
      iex> Co.scan(pid, "TSHIRT")
      :ok
      iex> Co.scan(pid, "TSHIRT")
      :ok
      iex> Co.total(pid)
      57.0

  For using a custom set of discount rules, the rules have to be passed as
  parameter to the `new` function.
  The rule set is a Map of product and discount type.

  ## Example: Passing a custom set of rules

      iex> alias App.Checkout, as: Co
      iex> discounts = %{ "MUG" => "2-for-1"}
      iex> {:ok, pid} = Co.new(discounts)
      iex> Co.scan(pid, "MUG")
      :ok
      iex> Co.total(pid)
      7.5
      iex> Co.scan(pid, "MUG")
      :ok
      iex> Co.total(pid)
      7.5
      iex> Co.scan(pid, "MUG")
      :ok
      iex> Co.total(pid)
      15.0

  For disabling all discount rules, then an empty Map has to be passed as parameter.

      iex> {:ok, _pid} = App.Checkout.new(%{})

  """
  def new() do
    # uses default pricing rules
    %{discounts: gen_price_rules()}
    |> start_link()
  end

  def new(pricing_rules) do
    %{discounts: pricing_rules}
    |> start_link()
  end

  @doc """
  Adds an item to the shopping cart. If the item is already in the cart,
  the quantity is increased.
  """
  def scan(pid, item_id) do
    GenServer.cast(pid, {:add, item_id})
  end

  @doc """
  Returns the total price of the items in the cart taking in consideration the
  discount rules.
  """
  def total(pid) do
    GenServer.call(pid, :total)
  end

  @doc """
  Initialization interface. See wrapper function `new`.
  """
  def start_link(opt) do
    state = Map.merge(%State{}, opt)
    GenServer.start_link(__MODULE__, state)
  end

  # Server interfaces

  @doc """
  GenServer initialization.
  """
  @impl true
  def init(state) do
    {:ok, state, {:continue, :load_prices}}
  end

  @doc """
  Second statge of initialization. This function does the heavy lifting.
  Here is where the files are loaded when needed.
  """
  @impl true
  def handle_continue(:load_prices, state) do
    result = is_test_env() |> load_prices()

    case result do
      {:ok, prices} ->
        init_state = Map.put(state, :prices, prices)
        {:noreply, init_state}

      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  @doc """
  Adds an item to the cart.

  ## Parameter

  - item_code: The item code to add to the cart.
  """
  @impl true
  def handle_cast({:add, item_code}, state) do
    # searches the item code in the price list
    case state.prices[item_code] do
      nil ->
        puts_log("The item '#{item_code}' is not a valid product")
        {:noreply, state}

      _item ->
        new_cart = add_item_to_cart(state.cart, item_code)
        {:noreply, %{state | cart: new_cart}}
    end
  end

  @doc """
  Calculates the total price of the items in the cart.

  First is calculated the discount based on the quanity of a product.
  Then the discount is applied when calculating product final price per unit.
  """
  @impl true
  def handle_call(:total, _form, state) do
    # todo: pass the discount to the calc_price as param
    total =
      state.cart
      |> calc_discount(state.discounts)
      |> calc_price(state.prices)

    {:reply, total, state}
  end

  @doc """
  Add items to the cart

  Searches for item code with the cart and if the item exist then the quantity
  for this item is increased by one.
  If the item was not previously in the cart, one item is added.
  The function returns the updated cart.

  ## Parameters

  - cart: Shopping cart with scanned items.
  - item_code: The item code to add to the cart.

  return:
    new_cart
  """
  def add_item_to_cart(cart, item_code) do
    case item_code in Map.keys(cart) do
      false ->
        # adds the new item to the cart
        Map.put(cart, item_code, 1)

      true ->
        # increments the units for the exisiting item
        {_quantity, new_cart} =
          Map.get_and_update!(
            cart,
            item_code,
            fn quantity -> {quantity, quantity + 1} end
          )

        new_cart
    end
  end

  @doc """
  Calculates the total price for the items in the cart.

  For each item in the shopping cart calculates the prices for the units without
  discount and the units with discount.
  The total cost for the items in the cart is returned.

  ## Assumtions:

  The discount has to be applied to the items in the cart before calling this
  function.
  Assumes that all the items in the cart are valid items.

  ## Parameters

  - cart: Shopping cart with scanned items.
  - prices: The product prices list.

  return:
    total_price
  """
  def calc_price(cart, prices) do
    Enum.reduce(cart, 0.0, fn {code, quantity, units_with_discount, discount}, acc ->
      price = prices[code]["price"]

      case units_with_discount do
        0 ->
          # this item has no discounts
          quantity * price + acc

        _ ->
          # calculates the price for units without discount
          no_discount_cost = (quantity - units_with_discount) * price
          # calculates the price for units with discount
          discount_cost = units_with_discount * price * (100 - discount) * 0.01
          # total cost for this item plus the accumulated
          no_discount_cost + discount_cost + acc
      end
    end)
  end

  @doc """
  Appends to each item the discounted units and the discounted percentage

  All the items in the card are append with the information about the discount.
  When no discount applies, these values are zero.
  When the discount applies the values are the units with discount and the
  percentage discounted from the full price.

  Example:

    {"MUG", 4, 2, 50}

  - "MUG" is the item code.
  - 4 is the scanned units for this item.
  - 2 is the units with discount.
  - 50 is the percentage of the price to discount (50%) to the 2 units above.

  ## Parameters

  - cart: Shopping cart with scanned items.
  - discount: Map with discount rules.

  return:
    {item_code, item_quantity, units_with_discount, discount_persentage}

  """
  def calc_discount(cart, discounts) do
    Enum.map(
      cart,
      fn {code, quantity} = item ->
        {disc_units, discount} = get_discount(item, discounts)
        {code, quantity, disc_units, discount}
      end
    )
  end

  @doc """
  Searches the item in the discount map and indicates how much discount applies.

  The discount my apply to all units, some or none, depending if the item has
  not discount assigned or there are not enough units to apply a discount.

  Since the units are added with the funtion `scan`, currently there is no need
  for guarding this function with: `when is_integer(quantity)`

  ## Parameters

  - item: A touple of item code and quantity.
  - discount: Type of discount to apply. See `gen_price_rules`.

  returns:
    {units_with_discount, percentage_discount}
  """
  def get_discount({code, quantity} = _item, discounts) do
    case discounts[code] do
      "2-for-1" when quantity > 1 ->
        # amount of units that this discount applies, group by pairs
        units = div(quantity, 2)
        # every second unit is free, 100% reduction
        discount = 100
        {units, discount}

      "bulk-of-3" when quantity >= 3 ->
        # from the 3rd unit all units get 5% reduction
        discount = 5
        {quantity, discount}

      _ ->
        # no enough units to apply a discount
        {0, 0}
    end
  end

  @doc """
  Generates a Map with default price discount rules.
  """
  def gen_price_rules() do
    %{
      "VOUCHER" => "2-for-1",
      "TSHIRT" => "bulk-of-3"
    }
  end

  @doc """
  Loads the list of prices

  Accepts a boolean as argument.

  ## Parameters

  - is_test_env:
    When `true`, the price list is generated with default values.
    When `false`, the price list is load from a JSON file.

  returns:
    {:ok, prices}
    {:errror, reason}
  """
  def load_prices(false = _is_test_env) do
    with path <- Application.get_env(:app, :prices_json_path),
         {:ok, content} <- File.read(path),
         {:ok, prices} <- Poison.decode(content) do
      {:ok, prices}
    else
      _ ->
        {:error, "Failed reading the prices config file."}
    end
  end

  # Generates a list of item prices for testing purposes.
  def load_prices(true = _is_test_env) do
    prices = %{
      "VOUCHER" => %{"name" => "Voucher", "price" => 5.00},
      "TSHIRT" => %{"name" => "T-Shirt", "price" => 20.00},
      "MUG" => %{"name" => "Coffee Mug", "price" => 7.50}
    }

    {:ok, prices}
  end

  # Prints a log line to the terminal.
  # The log is ignored in test environment.
  defp puts_log(text) do
    if not is_test_env() do
      IO.puts(text)
    end
  end
end
