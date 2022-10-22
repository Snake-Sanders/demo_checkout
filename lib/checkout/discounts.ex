defmodule Checkout.Discounts do
  # discount in percentage (10%)
  @bulk_discount 5

  @doc """
  Searches the item in the discount map and indicates how much discount applies.

  The discount might apply to all units, some or none, depending if the item has
  not discount assigned or there are not enough units to apply a discount.

  ## Parameters

  - item: A touple of item code and quantity.
  - discount: Type of discount to apply. See `gen_price_rules`.

  returns:
    {units_with_discount, percentage_discount}
  """
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
  return:

  {full_price_units, discounted_units, discount }
  """
  def get_discount_bulk_of({code, quantity} = _item, bulk_number) do
    if quantity >= bulk_number and code == "TSHIRT" do
      # no discount applies
      {0, quantity, @bulk_discount}
    else
      {quantity, 0, 0}
    end
  end

  @doc """
  Appends to each item the discounted units and the discounted percentage

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
  - discount: Map with discount rules. The rules have to be converted by
  `sanitize_rules` and have to have the format:
    %{"x-for" => {x, y}, "bulk-of" => x}

  return:
    {item_code, item_quantity, units_with_discount, discount_percentage}

  """

  # def calculate_discount(%{}, _discounts), do: %{}

  @spec calculate_discount(map(), map()) :: map()
  def calculate_discount(cart, discounts) do
    Enum.reduce(cart, %{}, fn {code, _quantity} = item, acc ->
      quantities = get_discount(item, discounts)
      Map.put(acc, code, quantities)
    end)
  end

  def get_bulk_discount_percentage(), do: @bulk_discount
end
