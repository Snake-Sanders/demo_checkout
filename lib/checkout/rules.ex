defmodule Checkout.Rules do
  def sanitize_rules([]), do: {:ok, %{}}

  def sanitize_rules(rules) do
    with {:ok, rule_list} <- validate_input_rules(rules),
         formated_rules <- convert_rules(rule_list) do
      validate_converted_rules(formated_rules)
    end
  end

  @doc """
  The user rules is a list. The list can have up to 2 rules
  and cannot have duplicated rules.
  """
  def validate_input_rules(rules) when is_list(rules) do
    with true <- length(rules) in 0..2,
         true <- Enum.uniq(rules) == rules do
      {:ok, rules}
    else
      _ -> {:error, "Invalid set of pricing rules"}
    end
  end

  def convert_rules(rules) when is_list(rules) do
    rules
    |> Enum.map(&parse_rule(&1))
  end

  def validate_converted_rules(rules) when is_list(rules) do
    {invalid_rules, valid_rules} =
      Enum.split_with(
        rules,
        fn rule -> :error in Map.keys(rule) end
      )

    case invalid_rules do
      [] ->
        {:ok, join_rules_into_map(valid_rules)}

      _ ->
        {:error, "invalid rules: #{invalid_rules}"}
    end
  end

  def join_rules_into_map(rules) when is_list(rules) do
    Enum.reduce(rules, %{}, fn rule, acc -> Map.merge(acc, rule) end)
  end

  def parse_rule(rule) do
    cond do
      String.starts_with?(rule, "bulk-") ->
        case parse_bulk_of(rule) do
          {:ok, value} -> %{"bulk-of" => value}
          :error -> {:error, "Invalid rule: '#{rule}'"}
        end

      String.contains?(rule, "-for-") ->
        case parse_x_for_y(rule) do
          {:ok, x, y} -> %{"x-for" => {x, y}}
          :error -> {:error, "Invalid rule: '#{rule}'"}
        end

      true ->
        {:error, "Invalid rule: '#{rule}'"}
    end
  end

  def parse_x_for_y(rule) do
    with [str_x, "for", str_y] <- String.split(rule, "-"),
         {x, _rest} <- Integer.parse(str_x),
         {y, _rest} <- Integer.parse(str_y) do
      {:ok, x, y}
    else
      _ ->
        :error
    end
  end

  def parse_bulk_of(rule) do
    with ["bulk", str_value] <- String.split(rule, "-"),
         {x, _rest} <- Integer.parse(str_value) do
      {:ok, x}
    else
      _ ->
        :error
    end
  end
end
