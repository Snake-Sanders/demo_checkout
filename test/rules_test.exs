defmodule RulesTest do
  use ExUnit.Case
  alias Checkout.Rules

  describe "Rule parsers." do
    test "parse x-for-y rule" do
      assert Rules.parse_x_for_y("2-for-1") == {:ok, 2, 1}
      assert Rules.parse_x_for_y("3-for-1") == {:ok, 3, 1}
      assert Rules.parse_x_for_y("5-for-2") == {:ok, 5, 2}
      assert Rules.parse_x_for_y("A-for-B") == :error
      assert Rules.parse_x_for_y("2-by-1") == :error
      assert Rules.parse_x_for_y("2 for 1") == :error
    end

    test "parse bulk of" do
      assert Rules.parse_bulk_of("bulk-3") == {:ok, 3}
      assert Rules.parse_bulk_of("bulk-2") == {:ok, 2}
      assert Rules.parse_bulk_of("bulk-5") == {:ok, 5}
      assert Rules.parse_bulk_of("bulk-A") == :error
      assert Rules.parse_bulk_of("bulk") == :error
      assert Rules.parse_bulk_of("3-bulk") == :error
    end

    test "parse rule" do
      assert Rules.parse_rule("2-for-1") == %{"x-for" => {2, 1}}
      assert Rules.parse_rule("bulk-3") == %{"bulk-of" => 3}
      assert Rules.parse_rule("no-bulk") == {:error, "Invalid rule: 'no-bulk'"}
      assert Rules.parse_rule("no-for-") == {:error, "Invalid rule: 'no-for-'"}
    end

    test "validate input rule list has no more than 2 elements" do
      # check type is a list
      assert Rules.validate_input_rules([]) == {:ok, []}

      # check quantity should be in 0..2
      assert Rules.validate_input_rules(["2-for-1"]) == {:ok, ["2-for-1"]}

      two_rules =
        ["2-for-1", "bulk-3"]
        |> Rules.validate_input_rules()

      assert two_rules == {:ok, ["2-for-1", "bulk-3"]}

      too_many_rules =
        ["2-for-1", "3-for-1", "bulk-3"]
        |> Rules.validate_input_rules()

      assert too_many_rules == {:error, "Invalid set of pricing rules"}

      duplicated_rules =
        ["3-for-1", "3-for-1"]
        |> Rules.validate_input_rules()

      assert duplicated_rules == {:error, "Invalid set of pricing rules"}
    end

    test "validate converted rules" do
      empty_rules =
        [%{}]
        |> Rules.validate_converted_rules()

      assert empty_rules == {:ok, %{}}

      one_rule =
        [%{"x-for" => {3, 1}}]
        |> Rules.validate_converted_rules()

      assert one_rule == {:ok, %{"x-for" => {3, 1}}}

      # invalid and valid rules
      # mixed_rules =
      #   [%{"x-for" => {3, 1}, :error => "invalid rules: 'bad rule'"}]
      #   |> Rules.validate_converted_rules()
      #   assert mixed_rules == {:error, %{"x-for" => {3, 1}}}
    end

    test "sanitize pricing rules" do
      rules = []
      assert Rules.sanitize_rules(rules) == {:ok, %{}}

      rules = ["2-for-1"]
      assert Rules.sanitize_rules(rules) == {:ok, %{"x-for" => {2, 1}}}

      rules = ["3-for-1"]
      assert Rules.sanitize_rules(rules) == {:ok, %{"x-for" => {3, 1}}}

      rules = ["bulk-3"]
      assert Rules.sanitize_rules(rules) == {:ok, %{"bulk-of" => 3}}

      rules = ["bulk-5"]
      assert Rules.sanitize_rules(rules) == {:ok, %{"bulk-of" => 5}}

      rules = ["3-for-1", "bulk-5"]
      assert Rules.sanitize_rules(rules) == {:ok, %{"x-for" => {3, 1}, "bulk-of" => 5}}

      # TODO: the user should be warned about overlapping rules
      rules = ["3-for-1", "2-for-1"]
      assert Rules.sanitize_rules(rules) == {:ok, %{"x-for" => {2, 1}}}
    end
  end
end
