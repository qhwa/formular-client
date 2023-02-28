defmodule ListenerTest.DelayedAdapter do
  alias Formular.Client.Cache
  use GenServer

  def start_link(config, opts) do
    GenServer.start_link(__MODULE__, {config, opts})
  end

  @impl true
  def init({config, opts}) do
    Process.send_after(self(), :load_formula, opts[:delay])
    {:ok, config}
  end

  @impl true
  def handle_info(:load_formula, config) do
    for {_, name, _} <- config.formulas do
      Cache.put(name, echo(name))
    end

    {:noreply, config}
  end

  defp echo(name) do
    inspect(name)
  end
end

defmodule Formular.Client.ListenerTest do
  alias Formular.Client.Config
  use ExUnit.Case, async: true

  describe "Waiting for formulas to be ready" do
    setup do
      config =
        Config.new(%{
          formulas: [
            "my-formula"
          ],
          adapter: {ListenerTest.DelayedAdapter, [delay: 200]},
          read_timeout: 400
        })

      {:ok, config: config}
    end

    test "it waits", context do
      assert {:ok, _pid} = start_client(context)
    end
  end

  describe "Timeout reading formulas" do
    setup do
      config =
        Config.new(%{
          formulas: [
            "my-formula-timeout"
          ],
          adapter: {ListenerTest.DelayedAdapter, [delay: 5_000]},
          read_timeout: 600
        })

      {:ok, config: config}
    end

    test "it raises an error", context do
      Process.flag(:trap_exit, true)

      assert {:error, _} = start_client(context)

      assert_receive {:EXIT, _pid, _}, 1_000
    end
  end

  defp start_client(%{config: config}) do
    Formular.Client.Supervisor.start_link(config)
  end
end
