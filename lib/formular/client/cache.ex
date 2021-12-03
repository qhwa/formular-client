defmodule Formular.Client.Cache do
  use GenServer

  @ets_table :formular_client_cache

  def start_link(args) do
    @ets_table = :ets.new(@ets_table, [:public, :set, :named_table, read_concurrency: true])
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_) do
    :ignore
  end

  def put(name, code_or_module),
    do: :ets.insert(@ets_table, {name, code_or_module})

  def get(name) do
    case :ets.lookup(@ets_table, name) do
      [{^name, code_or_module}] ->
        code_or_module

      [] ->
        nil
    end
  end
end
