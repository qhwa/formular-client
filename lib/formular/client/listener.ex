defmodule Formular.Client.Listener do
  alias Formular.Client.Config

  use GenServer
  require Logger

  def start_link(%Config{} = config) do
    GenServer.start_link(__MODULE__, config)
  end

  def start_link(config) do
    GenServer.start_link(__MODULE__, Config.new(config))
  end

  @impl true
  def init(config) do
    {:ok, _child} = start_adapter(config)
    wait_for_formulas(config)
    {:ok, config}
  end

  defp start_adapter(config) do
    DynamicSupervisor.start_child(
      Formular.Client.Instances,
      %{
        id: :erlang.unique_integer([:monotonic]),
        start: adapter_start_tuple(config),
        restart: :permanent
      }
    )
  end

  defp adapter_start_tuple(config) do
    case config.adapter do
      {adapter, options} when is_atom(adapter) ->
        {adapter, :start_link, [config, options]}

      other ->
        raise """
        Invalid adapter configuration, expecting `{:some_adapter_module, options}, but got: #{inspect(other)}`.
        """
    end
  end

  defp wait_for_formulas(%{formulas: formulas} = config) do
    all_loaded =
      Enum.all?(formulas, fn {_, name, _} ->
        Formular.Client.Cache.get(name)
      end)

    if all_loaded do
      :ok
    else
      :timer.sleep(200)
      wait_for_formulas(config)
    end
  end
end
