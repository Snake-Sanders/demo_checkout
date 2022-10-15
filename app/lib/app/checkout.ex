defmodule App.Checkout do
  use GenServer

  defmodule State do
    defstruct prices: %{}, discounts: %{}, cart: %{}
  end

  def is_test_env(), do: Mix.env() == :test

  # Client interfaces

  def new(pricing_rules \\ %{}) do
    start_link(pricing_rules)
  end

  def scan(pid, item_id) do
    GenServer.cast(pid, {:add, item_id})
  end

  def total(pid) do
    GenServer.call(pid, :total)
  end

  def start_link(opt) do
    GenServer.start_link(__MODULE__, %State{discounts: opt})
  end

  # Server interfaces

  @doc """
  When the json list gets bigger, then load it within the function
  `handle_continue`.
  """
  @impl true
  def init(state) do
    init_state = Map.put(state, :prices, load_prices())
    {:ok, init_state}
  end

  @impl true
  def handle_cast({:add, item_code}, state) do
    item = state.prices[item_code]

    case item do
      nil ->
        puts_log("The item '#{item_code}' is not a valid product")
        {:noreply, state}

      _ ->
        new_cart = add_item_to_cart(state.cart, item_code)
        {:noreply, %{state | cart: new_cart}}
    end
  end

  @doc """
  The discount is calculated first based on the quanity of a product.
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

  def add_item_to_cart(cart, item_code) do
    case item_code in Map.keys(cart) do
      false ->
        Map.put(cart, item_code, 1)

      true ->
        {_quantity, new_cart} =
          Map.get_and_update!(
            cart,
            item_code,
            fn quantity -> {quantity, quantity + 1} end
          )

        new_cart
    end
  end

  # Assumes that all the items in the cart are valid items.
  def calc_price(cart, prices) do
    Enum.reduce(cart, 0.0, fn {code, quantity, disc_units, discount}, acc ->
      price = prices[code].price

      case disc_units do
        0 ->
          quantity * price + acc

        _ ->
          no_discount_cost = (quantity - disc_units) * price
          discount_cost = disc_units * price * (100 - discount) * 0.01
          no_discount_cost + discount_cost + acc
      end
    end)
  end

  # Appends to each item in the cart how many units have discount
  # how much should be discounted for each.
  #
  # Cart items are returned as:
  # `{item_code, item_quantity, quantity_with_discount, discount}`
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
  Since the units are added with the funtion `scan`, currently there is no need
  for guarding this function with: `when is_integer(quantity)`
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

  # load the product prices list
  def load_prices() do
    if is_test_env() do
      %{
        "VOUCHER" => %{name: "Voucher", price: 5.00},
        "TSHIRT" => %{name: "T-Shirt", price: 20.00},
        "MUG" => %{name: "Coffee Mug", price: 7.50}
      }
    else
      path = Application.get_env(:app, :prices_json_path)
      {:ok, content} = File.read(path)
      Poison.decode!(content)
    end
  end

  defp puts_log(text) do
    if not is_test_env() do
      IO.puts(text)
    end
  end
end
