defmodule Formular.Client.MockError do
  @moduledoc """
  Error for the mocking configuration.
  """
  defexception [:message]

  @impl true
  def exception({:missing, missing}) do
    %Formular.Client.MockError{
      message: "Not all the formulas are mocked, missing: #{inspect(missing)}"
    }
  end
end

defmodule Formular.Client.Adapter.Mock do
  @moduledoc """
  A mocking adapter for testing.

  An example configuration for this adapter:

  ```elixir
  {
    formulas: [
      {"my-formula", fn _binding, _opts ->
        :ok
      end}
    ]
  }
  ```
  """

  alias Formular.Client.Cache

  require Logger

  def start_link(config, opts) do
    Logger.debug(["Starting mock formular intepreter."])

    {:ok, pid} = Agent.start_link(fn -> :ok end)

    formulas = opts[:formulas] || []

    ensure_all_formulas_provided!(config.formulas, formulas)

    Enum.each(formulas, fn {name, function} ->
      mock_global(name, function)
    end)

    {:ok, pid}
  end

  defp ensure_all_formulas_provided!(required, provided) do
    case ensure_all_formulas_provided(required, provided) do
      :ok ->
        :ok

      {:missing, missing} ->
        msg = """
        Not all the formulas were mocked, missing:
        #{inspect(missing)}.
        """

        Logger.error(msg)
        raise Formular.Client.MockError, {:missing, missing}
    end
  end

  defp ensure_all_formulas_provided(required, provided) do
    required = required |> Enum.map(&elem(&1, 0))
    provided = provided |> Enum.map(&elem(&1, 0))

    case required -- provided do
      [] ->
        :ok

      missing ->
        {:missing, missing}
    end
  end

  def mock_global(name, function)
      when is_binary(function)
      when is_function(function, 2) do
    Cache.put(name, function)
  end
end
