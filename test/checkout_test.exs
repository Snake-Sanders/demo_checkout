defmodule CheckoutTest do
  use ExUnit.Case
  # TODO: enable docs
  # doctest Checkout
  # TODO: remove all the :skip
  # alias Checkout.Cart

  defp get_prices() do
    %{
      "VOUCHER" => %{"name" => "Voucher", "price" => 5.00},
      "TSHIRT" => %{"name" => "T-Shirt", "price" => 20.00},
      "MUG" => %{"name" => "Coffee Mug", "price" => 7.50}
    }
  end

  # mock setup
  defp checkout_create(discounts) when is_list(discounts) do
    {:ok, rules} = Checkout.Rules.sanitize_rules(discounts)

    %Checkout{
      cart: %{},
      discounts: rules,
      prices: get_prices()
    }
  end

  describe "without discount:" do
    # @tag :skip
    test "create a checkout instance" do
      co = Checkout.new([])

      refute is_nil(co.prices)
      refute co.prices == %{}
      assert co.cart == %{}
      assert co.discounts == %{}
      assert Checkout.total(co) == 0.0
    end

    test "adding one item to the cart" do
      co = checkout_create([])
      co = Checkout.scan(co, "VOUCHER")

      assert co.cart == %{"VOUCHER" => 1}
      assert Checkout.total(co) == 5.0
    end

    test "adding 3 units of one product to the cart" do
      co =
        checkout_create([])
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")

      assert Checkout.total(co) == 15.0
    end

    test "invalid item is not added to the cart" do
      co =
        checkout_create([])
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("INVALID")
        |> Checkout.scan("VOUCHER")

      assert Checkout.total(co) == 25.0
    end
  end

  describe "with default discounts" do
    test "apply discount 2-for-1" do
      rules = ["2-for-1", "bulk-3"]
      co = checkout_create(rules)

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 5.0

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 5

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 10

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 10
    end
  end

end



# describe
# test "select a discount for bulk-of-3" do
#   rules = Checkout.gen_price_rules()
#   assert Checkout.get_discount({"TSHIRT", 0}, rules) == {0, 0}
#   assert Checkout.get_discount({"TSHIRT", 1}, rules) == {0, 0}
#   assert Checkout.get_discount({"TSHIRT", 3}, rules) == {3, 5}
#   assert Checkout.get_discount({"TSHIRT", 4}, rules) == {4, 5}
#   assert Checkout.get_discount({"TSHIRT", 7}, rules) == {7, 5}
# end

#   @tag :skip
#   test "select a discount for 2-of-1" do
#     rules = Checkout.gen_price_rules()
#     assert Checkout.get_discount({"VOUCHER", 0}, rules) == {0, 0}
#     assert Checkout.get_discount({"VOUCHER", 1}, rules) == {0, 0}
#     assert Checkout.get_discount({"VOUCHER", 2}, rules) == {1, 100}
#     assert Checkout.get_discount({"VOUCHER", 3}, rules) == {1, 100}
#     assert Checkout.get_discount({"VOUCHER", 4}, rules) == {2, 100}
#     assert Checkout.get_discount({"VOUCHER", 7}, rules) == {3, 100}
#   end

#   @tag :skip
#   @tag :skip
#   test "apply discount bulk-of-3" do
#     rules = Checkout.gen_price_rules()
#     {:ok, pid} = Checkout.new(rules)

#     Checkout.scan(pid, "TSHIRT")
#     assert Checkout.total(pid) == 20

#     Checkout.scan(pid, "TSHIRT")
#     assert Checkout.total(pid) == 40

#     Checkout.scan(pid, "TSHIRT")
#     assert Checkout.total(pid) == 57

#     Checkout.scan(pid, "TSHIRT")
#     assert Checkout.total(pid) == 76
#   end

#   @tag :skip
#   test "discount for mixed items: Example 1" do
#     rules = Checkout.gen_price_rules()
#     {:ok, pid} = Checkout.new(rules)

#     Checkout.scan(pid, "VOUCHER")
#     Checkout.scan(pid, "TSHIRT")
#     Checkout.scan(pid, "MUG")
#     assert Checkout.total(pid) == 32.50
#   end

#   @tag :skip
#   test "discount for mixed items: Example 2" do
#     rules = Checkout.gen_price_rules()
#     {:ok, pid} = Checkout.new(rules)

#     Checkout.scan(pid, "TSHIRT")
#     Checkout.scan(pid, "TSHIRT")
#     Checkout.scan(pid, "TSHIRT")
#     Checkout.scan(pid, "VOUCHER")
#     Checkout.scan(pid, "TSHIRT")
#     assert Checkout.total(pid) == 81.0
#   end

#   @tag :skip
#   test "discount for mixed items: Example 3" do
#     rules = Checkout.gen_price_rules()
#     {:ok, pid} = Checkout.new(rules)

#     Checkout.scan(pid, "VOUCHER")
#     Checkout.scan(pid, "TSHIRT")
#     Checkout.scan(pid, "VOUCHER")
#     Checkout.scan(pid, "VOUCHER")
#     Checkout.scan(pid, "MUG")
#     Checkout.scan(pid, "TSHIRT")
#     Checkout.scan(pid, "TSHIRT")
#     assert Checkout.total(pid) == 74.50
#   end
# end

# describe "with custom discounts" do
#   @tag :skip
#   test "applying MUG discount" do
#     discounts = %{"MUG" => "2-for-1"}
#     {:ok, pid} = Checkout.new(discounts)

#     Checkout.scan(pid, "MUG")
#     Checkout.scan(pid, "MUG")
#     assert Checkout.total(pid) == 7.5
#   end
# end

# end # end module

# @doc """
# Generates a Map with default prices discount rules.
# """
# defp gen_price_rules() do
#   %{
#     "VOUCHER" => "2-for-1",
#     "TSHIRT" => "bulk-of-3"
#   }
# end

# # Generates a list of item prices.
# def load_prices() do
#   prices = %{
#     "VOUCHER" => %{"name" => "Voucher", "price" => 5.00},
#     "TSHIRT" => %{"name" => "T-Shirt", "price" => 20.00},
#     "MUG" => %{"name" => "Coffee Mug", "price" => 7.50}
#   }

#   {:ok, prices}
# end
