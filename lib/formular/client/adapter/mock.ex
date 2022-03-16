defmodule Formular.Client.Adapter.Mock do
  alias Formular.Client.Cache

  def start_link(_config, opts) do
    {:ok, pid} = Agent.start_link(fn -> :ok end)

    case opts[:formulas] do
      formulas when is_list(formulas) ->
        Enum.each(formulas, fn {name, function} ->
          mock_global(name, function)
        end)

      nil ->
        :ok
    end

    {:ok, pid}
  end

  def mock_global(name, function)
      when is_binary(function)
      when is_function(function, 2) do
    Cache.put(name, function)
  end
end
