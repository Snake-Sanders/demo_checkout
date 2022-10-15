defmodule CheckoutTest do
  use ExUnit.Case
  # doctest App

  alias App.Checkout

  def get_price_rules() do
    [
      {"2-for-1", [VOUCHER]},
      {"bulk-of-3", [TSHIRT]}
    ]
  end

  describe "without discount" do
    test "Create a checkout instance" do
      {result, pid} = Checkout.new()
      assert result == :ok
      assert Checkout.total(pid) == 0.0
    end

    test "adding one item to the cart" do
      {:ok, pid} = Checkout.new()
      Checkout.scan(pid, "VOUCHER")
      assert Checkout.total(pid) == 5.0
    end

    test "adding 3 units of one item to the cart" do
      {:ok, pid} = Checkout.new()
      Checkout.scan(pid, "VOUCHER") # 5€
      Checkout.scan(pid, "VOUCHER") # 5€
      Checkout.scan(pid, "VOUCHER") # 5€
      assert Checkout.total(pid) == 15.0
    end

    test "invalid item is not added to the cart" do
      {:ok, pid} = Checkout.new()
      Checkout.scan(pid, "TSHIRT") # 20€
      Checkout.scan(pid, "INVALID") # 0€
      Checkout.scan(pid, "VOUCHER") # 5€
      assert Checkout.total(pid) == 25.0
    end
  end

  describe "with discount" do
    @tag :skip
    test "apply discount 2-for-1" do
      rules = get_price_rules()
      {:ok, pid} = Checkout.new(rules)
      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 20

      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 38 # 2u at 19 € each

      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 58 # 2u at 19 € + 1u full price

      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 76 # 4u at 19 € each
    end
  end
end
