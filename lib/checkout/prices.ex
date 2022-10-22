defmodule Checkout.Prices do
  # TODO: Rename unit to Product

  @doc """
  Loads the list of prices

  Accepts a boolean as argument.

  ## Parameters

  - is_test_env:
    When `true`, the price list is generated with default values.
    When `false`, the price list is load from a JSON file.

  returns:
    {:ok, prices}
    {:errror, reason}
  """
  def load_prices() do
    path = Application.get_env(:app, :prices_json_path)

    with {:ok, content} <- File.read(path),
         {:ok, prices} <- Poison.decode(content) do
      {:ok, prices}
    else
      _ ->
        {:error, "Failed reading the prices list file: #{path}."}
    end
  end
end
