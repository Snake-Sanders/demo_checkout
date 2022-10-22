defmodule DiscountsTest do
  use ExUnit.Case
  alias Checkout.Discounts

  # defp get_prices() do
  #   %{
  #     "VOUCHER" => %{"name" => "Voucher", "price" => 5.00},
  #     "TSHIRT" => %{"name" => "T-Shirt", "price" => 20.00},
  #     "MUG" => %{"name" => "Coffee Mug", "price" => 7.50}
  #   }
  # end

  describe "Get discount x for y:" do
    test "2 for 1" do
      result = Discounts.get_discount_x_for_y({"VOUCHER", 1}, {2, 1})
      assert result == {1, 0, 0}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 2}, {2, 1})
      assert result == {1, 1, 100}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 3}, {2, 1})
      assert result == {2, 1, 100}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 4}, {2, 1})
      assert result == {2, 2, 100}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 7}, {2, 1})
      assert result == {4, 3, 100}
    end

    test "3 for 2" do
      result = Discounts.get_discount_x_for_y({"VOUCHER", 1}, {3, 2})
      assert result == {1, 0, 0}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 2}, {3, 2})
      assert result == {2, 0, 0}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 3}, {3, 2})
      assert result == {2, 1, 100}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 4}, {3, 2})
      assert result == {3, 1, 100}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 7}, {3, 2})
      assert result == {5, 2, 100}
    end

    test "5 for 2" do
      result = Discounts.get_discount_x_for_y({"VOUCHER", 1}, {5, 2})
      assert result == {1, 0, 0}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 4}, {5, 2})
      assert result == {4, 0, 0}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 5}, {5, 2})
      assert result == {2, 3, 100}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 7}, {5, 2})
      assert result == {4, 3, 100}

      result = Discounts.get_discount_x_for_y({"VOUCHER", 11}, {5, 2})
      assert result == {5, 6, 100}
    end
  end

  describe "Get discount bulk of x:" do
    test "bulk of 3" do
      result = Discounts.get_discount_bulk_of({"TSHIRT", 1}, 3)
      assert result == {1, 0, 0}

      result = Discounts.get_discount_bulk_of({"TSHIRT", 2}, 3)
      assert result == {2, 0, 0}

      result = Discounts.get_discount_bulk_of({"TSHIRT", 3}, 3)
      assert result == {0, 3, 10}

      result = Discounts.get_discount_bulk_of({"TSHIRT", 4}, 3)
      assert result == {0, 4, 10}

      result = Discounts.get_discount_bulk_of({"TSHIRT", 9}, 3)
      assert result == {0, 9, 10}
    end

    test "bulk of 4" do
      result = Discounts.get_discount_bulk_of({"TSHIRT", 1}, 4)
      assert result == {1, 0, 0}

      result = Discounts.get_discount_bulk_of({"TSHIRT", 3}, 4)
      assert result == {3, 0, 0}

      result = Discounts.get_discount_bulk_of({"TSHIRT", 4}, 4)
      assert result == {0, 4, 10}

      result = Discounts.get_discount_bulk_of({"TSHIRT", 9}, 4)
      assert result == {0, 9, 10}
    end
  end

  describe "x for y: " do
    test "3-for-2 discount on Vouchers but the quantity is no enough" do
      discounts = %{"x-for" => {3, 2}}
      result = Discounts.calculate_discount(%{"VOUCHER" => 1}, discounts)
      assert result == %{"VOUCHER" => {1, 0, 0}}
    end

    test "3-for-2 discount but it does not apply to Tshirt" do
      discounts = %{"x-for" => {3, 2}}
      result = Discounts.calculate_discount(%{"TSHIRT" => 3}, discounts)
      assert result == %{"TSHIRT" => {3, 0, 0}}
    end

    test "3-for-2 discount but it does not apply to Mugs" do
      discounts = %{"x-for" => {3, 2}}
      result = Discounts.calculate_discount(%{"MUG" => 5}, discounts)
      assert result == %{"MUG" => {5, 0, 0}}
    end

    test "3-for-2 discount is only applied to Vouchers" do
      discounts = %{
        "x-for" => {3, 2},
        "bulk-of" => 3
      }

      result = Discounts.calculate_discount(%{"VOUCHER" => 3}, discounts)
      assert result == %{"VOUCHER" => {2, 1, 100}}

      result = Discounts.calculate_discount(%{"VOUCHER" => 7}, discounts)
      assert result == %{"VOUCHER" => {5, 2, 100}}
    end
  end

  describe "bulk of: " do
    test "bulk-3 discount on Vouchers but the quantity is no enough" do
      discounts = %{"bulk-of" => 3}
      result = Discounts.calculate_discount(%{"TSHIRT" => 2}, discounts)
      assert result == %{"TSHIRT" => {2, 0, 0}}
    end

    test "bulk-3 discount but it does not apply to Vouchers" do
      discounts = %{"bulk-of" => 3}
      result = Discounts.calculate_discount(%{"VOUCHER" => 2}, discounts)
      assert result == %{"VOUCHER" => {2, 0, 0}}
    end

    test "bulk-3 discount but it does not apply to Mugs" do
      discounts = %{"bulk-of" => 3}
      result = Discounts.calculate_discount(%{"MUG" => 5}, discounts)
      assert result == %{"MUG" => {5, 0, 0}}
    end

    test "bulk-3 discount is only applied to Tshirt" do
      discounts = %{
        "x-for" => {3, 2},
        "bulk-of" => 3
      }

      result = Discounts.calculate_discount(%{"TSHIRT" => 3}, discounts)
      assert result == %{"TSHIRT" => {0, 3, 10}}

      result = Discounts.calculate_discount(%{"TSHIRT" => 7}, discounts)
      assert result == %{"TSHIRT" => {0, 7, 10}}
    end
  end
end
