defmodule CheckoutTest do
  use ExUnit.Case
  #doctest App

  alias App.Checkout

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
end
