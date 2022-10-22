defmodule Checkout.Prices do
  # TODO: Rename unit to Product

  @doc """
  Loads the list of prices

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
