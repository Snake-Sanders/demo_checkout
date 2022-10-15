defmodule CheckoutTest do
  use ExUnit.Case
  # doctest App

  alias App.Checkout

  def get_price_rules() do
    %{
      "VOUCHER" => "2-for-1",
      "TSHIRT" => "bulk-of-3"
    }
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
      Checkout.scan(pid, "VOUCHER")
      Checkout.scan(pid, "VOUCHER")
      Checkout.scan(pid, "VOUCHER")
      assert Checkout.total(pid) == 15.0
    end

    test "invalid item is not added to the cart" do
      {:ok, pid} = Checkout.new()
      Checkout.scan(pid, "TSHIRT")
      Checkout.scan(pid, "INVALID")
      Checkout.scan(pid, "VOUCHER")
      assert Checkout.total(pid) == 25.0
    end
  end

  describe "with discount" do
    test "select a discount for bulk-of-3" do
      rules = get_price_rules()
      assert Checkout.get_discount({"TSHIRT", 0}, rules) == {0, 0}
      assert Checkout.get_discount({"TSHIRT", 1}, rules) == {0, 0}
      assert Checkout.get_discount({"TSHIRT", 3}, rules) == {3, 5}
      assert Checkout.get_discount({"TSHIRT", 4}, rules) == {4, 5}
      assert Checkout.get_discount({"TSHIRT", 7}, rules) == {7, 5}
    end

    test "select a discount for 2-of-1" do
      rules = get_price_rules()
      assert Checkout.get_discount({"VOUCHER", 0}, rules) == {0, 0}
      assert Checkout.get_discount({"VOUCHER", 1}, rules) == {0, 0}
      assert Checkout.get_discount({"VOUCHER", 2}, rules) == {1, 100}
      assert Checkout.get_discount({"VOUCHER", 3}, rules) == {1, 100}
      assert Checkout.get_discount({"VOUCHER", 4}, rules) == {2, 100}
      assert Checkout.get_discount({"VOUCHER", 7}, rules) == {3, 100}
    end

    test "apply discount 2-for-1" do
      rules = get_price_rules()
      {:ok, pid} = Checkout.new(rules)

      Checkout.scan(pid, "VOUCHER")
      assert Checkout.total(pid) == 5

      Checkout.scan(pid, "VOUCHER")
      assert Checkout.total(pid) == 5

      Checkout.scan(pid, "VOUCHER")
      assert Checkout.total(pid) == 10

      Checkout.scan(pid, "VOUCHER")
      assert Checkout.total(pid) == 10
    end

    test "apply discount bulk-of-3" do
      rules = get_price_rules()
      {:ok, pid} = Checkout.new(rules)

      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 20

      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 40

      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 57

      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 76
    end

    test "discount for mixed items: Example 1" do
      rules = get_price_rules()
      {:ok, pid} = Checkout.new(rules)

      Checkout.scan(pid, "VOUCHER")
      Checkout.scan(pid, "TSHIRT")
      Checkout.scan(pid, "MUG")
      assert Checkout.total(pid) == 32.50
    end

    test "discount for mixed items: Example 2" do
      rules = get_price_rules()
      {:ok, pid} = Checkout.new(rules)

      Checkout.scan(pid, "TSHIRT")
      Checkout.scan(pid, "TSHIRT")
      Checkout.scan(pid, "TSHIRT")
      Checkout.scan(pid, "VOUCHER")
      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 81.0
    end

    test "discount for mixed items: Example 3" do
      rules = get_price_rules()
      {:ok, pid} = Checkout.new(rules)

      Checkout.scan(pid, "VOUCHER")
      Checkout.scan(pid, "TSHIRT")
      Checkout.scan(pid, "VOUCHER")
      Checkout.scan(pid, "VOUCHER")
      Checkout.scan(pid, "MUG")
      Checkout.scan(pid, "TSHIRT")
      Checkout.scan(pid, "TSHIRT")
      assert Checkout.total(pid) == 74.50
    end
  end
end
