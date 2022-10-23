defmodule CartTest do
  use ExUnit.Case
  doctest Checkout.Cart
  alias Checkout.Cart

  defp get_prices() do
    %{
      "VOUCHER" => %{"name" => "Voucher", "price" => 5.00},
      "TSHIRT" => %{"name" => "T-Shirt", "price" => 20.00},
      "MUG" => %{"name" => "Coffee Mug", "price" => 7.50}
    }
  end

  describe "Add items to cart" do
    test "Add: 1 Mug" do
      cart = Cart.add_item(%{}, "MUG")
      assert cart == %{"MUG" => 1}
    end

    test "Add: 2 Mugs" do
      cart =
        %{}
        |> Cart.add_item("MUG")
        |> Cart.add_item("MUG")

      assert cart == %{"MUG" => 2}
    end

    test "Add: 3 Mugs, 5 tshirt, 2 voucher" do
      cart =
        %{}
        |> Cart.add_item("MUG")
        |> Cart.add_item("MUG")
        |> Cart.add_item("MUG")
        |> Cart.add_item("TSHIRT")
        |> Cart.add_item("TSHIRT")
        |> Cart.add_item("TSHIRT")
        |> Cart.add_item("TSHIRT")
        |> Cart.add_item("TSHIRT")
        |> Cart.add_item("VOUCHER")
        |> Cart.add_item("VOUCHER")

      assert cart == %{
               "MUG" => 3,
               "TSHIRT" => 5,
               "VOUCHER" => 2
             }
    end
  end

  describe "Calculate prices" do
    test "Cart with: 1 Mug" do
      prices = get_prices()

      cart = %{
        "MUG" => {1, 0, 0}
      }

      assert Cart.calculate_price(cart, prices) == 7.5
    end

    test "Cart with: 1 Mug, 1 t-shirt & 1 Voucher" do
      prices = get_prices()

      cart = %{
        "MUG" => {1, 0, 0},
        "TSHIRT" => {1, 0, 0},
        "VOUCHER" => {1, 0, 0}
      }

      assert Cart.calculate_price(cart, prices) == 32.5
    end

    test "Cart with: 2 Mug, 3 t-shirt & 5 Voucher" do
      prices = get_prices()

      cart = %{
        "MUG" => {2, 0, 0},
        "TSHIRT" => {3, 0, 0},
        "VOUCHER" => {5, 0, 0}
      }

      assert Cart.calculate_price(cart, prices) == 100.0
    end
  end
end
