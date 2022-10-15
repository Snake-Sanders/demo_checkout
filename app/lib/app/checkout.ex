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

  @impl true
  def handle_call(:total, _form, state) do
    total =
      state.cart
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
    Enum.reduce(cart, 0.0, fn {code, quantity}, acc ->
      price = prices[code].price
      quantity * price + acc
    end)
  end

  # load the product prices list
  def load_prices() do
    # todo: load this list from a JSON file defined in configuration
    %{
      "VOUCHER" => %{name: "Voucher", price: 5.00},
      "TSHIRT" => %{name: "T-Shirt", price: 20.00},
      "MUG" => %{name: "Coffee Mug", price: 7.50}
    }
  end

  defp puts_log(text) do
    if not is_test_env() do
      IO.puts(text)
    end
  end
end
