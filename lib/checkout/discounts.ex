defmodule Checkout.Discounts do
  # discount in percentage
  @bulk_discount 5

  @doc """
  Searches the item in the discount map and indicates how much discount applies.

  The discount might apply to all units, some or none. That dependes on some
  conditions. A discount applies if the item has a discount associated and the
  there are enough items.

  Only two items are applicable for discounts: `VOUCHER` and `TSHIRT`.

  ## Parameters

  - item: A touple of item code and quantity of this item.
  - discounts: The map of discounts.

  returns:

    When the item has not discount, the funciton returns a touple with the
    values:
    `{quantity, 0, 0}`.
    Quantity means all the items has full price, the following
    two zeroes mean: no unit has discount, no discount percentage applies.

    When the item has discount, the function returns a touple with the values:
    `{full_price_units, discounted_units, percentage_discount}`.
    `full_price_units` are the units without discount.
    `discounted_units` are the units with discount
    `percentage_discount` is the discount percentage to apply to the discounted
    units. This is, 100, is 100% discount, the discounted unit prices is 0.
    With 50, the discounted unit prices is the half.
  """
  @spec get_discount(tuple(), map()) :: any()
  def get_discount({code, quantity} = item, discounts) do
    result =
      case code do
        "VOUCHER" ->
          case "x-for" in Map.keys(discounts) do
            true ->
              get_discount_x_for_y(item, discounts["x-for"])

            false ->
              :no_discount
          end

        "TSHIRT" ->
          case "bulk-of" in Map.keys(discounts) do
            true ->
              get_discount_bulk_of(item, discounts["bulk-of"])

            false ->
              :no_discount
          end

        _no_discount ->
          :no_discount
      end

    case result do
      :no_discount -> {quantity, 0, 0}
      _ -> result
    end
  end

  @doc """
  Checkes if the quantity of the item units are enough to apply the discount.

  return:
  returns a tuple with how many items have no discount, how many have discount
  and how much is discounted in percentage.

  `{full_price_units, discounted_units, discount}`
  """
  def get_discount_x_for_y({_code, quantity} = _item, {buy_x, pay_y}) do
    groups = div(quantity, buy_x)
    # amount of units that this discount applies, group by pairs
    discounted_units = (buy_x - pay_y) * groups
    full_price_units = quantity - discounted_units

    # when there are discounted items, the discount is 100% reduction
    discount = if(discounted_units > 0, do: 100, else: 0)

    {full_price_units, discounted_units, discount}
  end

  @doc """
  Checkes if the quantity of the item units are enough to apply the discount.

  return:
  returns a tuple with how many items have no discount, how many have discount
  and how much is discounted in percentage.

  `{full_price_units, discounted_units, discount}`
  """
  def get_discount_bulk_of({_code, quantity} = _item, bulk_number) do
    if quantity >= bulk_number do
      {0, quantity, @bulk_discount}
    else
      # no discount applies
      {quantity, 0, 0}
    end
  end

  @doc """
  Retrieves the discount that applies to each item in the cart.

  All the items in the card are append with the information about the discount.
  When no discount applies, these values are zero.
  When the discount applies the values are the units with discount and the
  percentage discounted from the full price.

  Example:

    {"VOUCHER", 2, 1, 100}

  Assuming the cart has 3 Vouchers and there is a 3-for-2 discount.
  - "VOUCHER" is the item code.
  - 2 is the units to pay full price.
  - 1 is the units with discount.
  - 100 is the percentage of the price to discount (100%) to one unit.

  ## Parameters

  - cart: Shopping cart with scanned items.
  - discounts: Map with discount rules. The rules have to be converted by
  `sanitize_rules` and have to have the format:
    %{"x-for" => {x, y}, "bulk-of" => x}

  return:
    {item_code, full_price_units, discounted_units, discount_percentage}

  """
  @spec calculate_discount(map(), map()) :: map()
  def calculate_discount(cart, discounts) do
    Enum.reduce(cart, %{}, fn {code, _quantity} = item, acc ->
      quantities = get_discount(item, discounts)
      Map.put(acc, code, quantities)
    end)
  end
end
