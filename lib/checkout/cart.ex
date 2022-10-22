defmodule Checkout.Cart do
  @doc """
  Add an item to the cart

  Searches for the item code within the items in the cart and if the item exists
  then the quantity for this item is increased by one.
  If the item was not previously in the cart, this item is added.
  The function returns the updated cart.

  ## Parameters

  - cart: Shopping cart with scanned items.
  - item_code: The item code to add to the cart.

  return:
    new_cart
  """
  def add_item(%{} = cart, item_code) do
    if item_code in Map.keys(cart) do
      # increments the units for the exisiting item
      new_quantity = cart[item_code] + 1
      put_in(cart[item_code], new_quantity)
    else
      # adds the new item to the cart
      Map.merge(cart, %{item_code => 1})
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
  def calculate_price(%{} = cart, prices) do
    Enum.reduce(cart, 0.0, fn {code, attributes}, acc ->
      {full_price_units, discounted_units, discount} = attributes
      price = prices[code]["price"]
      # calculates the price for units without discount
      no_discount_cost = full_price_units * price
      # calculates the price for units with discount
      discount_cost = discounted_units * price * (100 - discount) * 0.01
      # total cost for this item plus the accumulated
      no_discount_cost + discount_cost + acc
    end)
  end
end
