defmodule CheckoutTest do
  use ExUnit.Case
  doctest Checkout

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

  describe "Applying discounts:" do
    test "2-for-1" do
      rules = ["2-for-1", "bulk-3"]
      co = checkout_create(rules)

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 5

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 5

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 10

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 10
    end

    test "3-for-1" do
      rules = ["3-for-1"]

      co =
        checkout_create(rules)
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")

      assert Checkout.total(co) == 5

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 10
    end

    test "5-for-2" do
      rules = ["5-for-2"]

      co =
        checkout_create(rules)
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")

      assert Checkout.total(co) == 10

      co = Checkout.scan(co, "VOUCHER")
      assert Checkout.total(co) == 15
    end

    test "bulk-of-3" do
      rules = ["2-for-1", "bulk-3"]
      co = checkout_create(rules)

      co = Checkout.scan(co, "TSHIRT")
      assert Checkout.total(co) == 20

      co = Checkout.scan(co, "TSHIRT")
      assert Checkout.total(co) == 40

      co = Checkout.scan(co, "TSHIRT")
      assert Checkout.total(co) == 57

      co = Checkout.scan(co, "TSHIRT")
      assert Checkout.total(co) == 76
    end

    test "discount for mixed items: Example 1" do
      rules = ["2-for-1", "bulk-3"]

      co =
        checkout_create(rules)
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("MUG")

      assert Checkout.total(co) == 32.50
    end

    test "discount for mixed items: Example 2" do
      rules = ["2-for-1", "bulk-3"]

      co =
        checkout_create(rules)
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("VOUCHER")

      assert Checkout.total(co) == 25.0
    end

    test "discount for mixed items: Example 3" do
      rules = ["2-for-1", "bulk-3"]

      co =
        checkout_create(rules)
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("TSHIRT")

      assert Checkout.total(co) == 81.0
    end

    test "discount for mixed items: Example 4" do
      rules = ["2-for-1", "bulk-3"]

      co =
        checkout_create(rules)
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("VOUCHER")
        |> Checkout.scan("MUG")
        |> Checkout.scan("TSHIRT")
        |> Checkout.scan("TSHIRT")

      assert Checkout.total(co) == 74.50
    end
  end
end
