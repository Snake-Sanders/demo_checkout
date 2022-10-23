defmodule Checkout.Prices do
  @doc """
  Loads the list of prices

  returns:
    {:ok, prices}
    {:error, reason}
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
