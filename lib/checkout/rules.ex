defmodule Checkout.Rules do
  @doc """
  Inpects the pricing rules given as input parameter to Checkout module. Runs a
  plausibility check and converts the input for internal manipulation.
  Then determines whether the converted rules are valid or not.

  ## Parameters

  - rules: Pricing rules list

  return

  {:ok, valid_rules}
  {:error, reason}
  """
  @spec sanitize_rules(list(String.t())) ::
          {:ok, map()} | {:error, String.t()} | any()
  def sanitize_rules([]), do: {:ok, %{}}

  def sanitize_rules(rules) do
    with {:ok, rule_list} <- validate_input_rules(rules),
         formated_rules <- convert_rules(rule_list) do
      validate_converted_rules(formated_rules)
    else
      {:error, reason} -> {:error, reason}
      _other_error -> {:error, "Unexpected error while sanitizing inputs."}
    end
  end

  @doc """
  Validates the user input list of rules.

  The list can have up to 2 rules.
  There cannot be duplicated rules.

  ## Parameters

  - rules: List of pricing rules.

  return:
  When valid, it returns the pricing list
  """
  @spec validate_input_rules(list()) :: {:ok, list()} | {:error, String.t()}
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

  @doc """
  Checks that all converted rules are valid.

  ## Parameters
  - rules: A list of converted rules with the format:
    {:ok, %{rule => attribues}}
    {:error, reason}

  return:
    {:ok, rules_map}
    {:error, reason}
  """
  @spec validate_converted_rules(list()) :: {:ok, map()} | {:error, String.t()}
  def validate_converted_rules([:ok, %{}]), do: {:ok, %{}}

  def validate_converted_rules(rules) when is_list(rules) do
    # group the rules as valid and invalid
    {valid_rules, invalid_rules} =
      Enum.split_with(
        rules,
        fn {key, _value} -> key == :ok end
      )

    case invalid_rules do
      [] ->
        # happy case, all rules are valid
        ok_rules =
          valid_rules
          |> Enum.map(fn {:ok, r} -> r end)
          |> join_rules_into_map()

        {:ok, ok_rules}

      _ ->
        # at least one rule is invalid, return error
        nok_rules =
          invalid_rules
          |> Enum.map(fn {:error, r} -> r end)

        {:error, nok_rules}
    end
  end

  # merge a list of rules into one map
  defp join_rules_into_map(rules) when is_list(rules) do
    Enum.reduce(rules, %{}, fn rule, acc -> Map.merge(acc, rule) end)
  end

  @doc """
  Given a `rule`, it determines the type of rule and extracts the rule data from
  its name.

  E.g.:
  Given a rule name `3-for-2`, the general name for this rule is `x-for` and the
  embedded information within the name is buy `3` and pay for `2`.
  `3` and `2` are converted to touples.

  The rule is transformed to: `%{"x-for" => {3, 2}}`.

  Similarly for `bulk-3`, it gets converted to `%{"bulk-of" => 3}`.

  ## Parameters
  - rule: pricing rule name

  return:
  the parse rule with a generalized name and its values
  """
  @spec parse_rule(String.t()) :: {:ok, any()} | :error
  def parse_rule(rule) do
    result =
      cond do
        String.starts_with?(rule, "bulk-") ->
          case parse_bulk_of(rule) do
            {:ok, value} -> %{"bulk-of" => value}
            _ -> :error
          end

        String.contains?(rule, "-for-") ->
          case parse_x_for_y(rule) do
            {:ok, x, y} -> %{"x-for" => {x, y}}
            _ -> :error
          end

        true ->
          :error
      end

    if result == :error do
      {:error, "invalid rule: '#{rule}'"}
    else
      {:ok, result}
    end
  end

  @doc """
  Parses the rules of the type `x-for-y`, e.g. `3-for-2`.

  ## Parameters
  - rule: the name of the rule

  return:
  When the format is correct, it returns the integer values for this rule.
  In the previous example, `3-for-2`: `{3, 2}`
  """
  @spec parse_x_for_y(String.t()) :: {:ok, integer(), integer()} | :error
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

  @doc """
  Parses the rules of the type `bulk-x`, e.g. `bulk-3`.

  ## Parameters
  - rule: the name of the rule

  return:
  When the format is correct, it returns the integer value for this rule.
  In the previous example, `bulk-3`: `3`
  """
  @spec parse_bulk_of(String.t()) :: {:ok, integer()} | :error
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
