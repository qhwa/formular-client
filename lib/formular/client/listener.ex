defmodule Formular.Client.Listener do
  alias Formular.Client.Config

  use GenServer
  require Logger

  def start_link(%Config{} = config) do
    GenServer.start_link(__MODULE__, config)
  end

  def start_link(config) do
    config |> Config.new() |> start_link()
  end

  @impl true
  def init(config) do
    Logger.info("Starting Formular Client.")

    {:ok, _child} = start_adapter(config)

    # Attention here: we're blocking the starting process
    # because we want to make sure other parts of the 
    # application can only be started AFTER all the formulas
    # has been loaded.
    wait_for_formulas(
      _now = :erlang.monotonic_time(),
      config
    )

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

  defp wait_for_formulas(start_at, %{formulas: formulas} = config) do
    missing =
      formulas
      |> Stream.map(fn {_, name, _} -> name end)
      |> Enum.reject(&Formular.Client.Cache.get(&1))

    case missing do
      [] ->
        :ok

      _ ->
        case config.read_timeout do
          :infinity ->
            :ok

          n when is_integer(n) ->
            if div(:erlang.monotonic_time() - start_at, 1_000_000) > n do
              raise "timeout reading formulas"
            end

            :timer.sleep(200)
            wait_for_formulas(start_at, config)
        end
    end
  end
end
