defmodule Formular.Client.PubSub do
  @scope :formular_pubsub
  @type formula_name :: String.t()
  @type code :: String.t()
  @type event :: code_change_event() | compiled_event() | compile_failed_event()
  @type code_change_event ::
          {:code_change, formula_name(), old_code :: code(), new_code :: code()}
  @type compiled_event :: {:compiled, formula_name(), code(), compile_event_metadata()}
  @type compile_failed_event ::
          {:compile_failed, formula_name(), err :: any(), code(), compile_event_metadata()}
  @type compile_event_metadata :: [{:mod, module()} | {:context, module()}]

  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Subscribe the change events for a given formula.

  Notice that a subscriber can subscribe a formula change for multiple times.
  In such cases, it also needs to unsubscribe for the same amount of times
  to stop receiving messages.
  """
  @spec subscribe(formula_name(), pid()) :: :ok
  def subscribe(formula_name, pid \\ self()),
    do: :pg.join(@scope, formula_name, pid)

  @doc """
  Stop receiving events from dispatcher.
  """
  @spec unsubscribe(formula_name(), pid()) :: :ok
  def unsubscribe(formula_name, pid \\ self()),
    do: :pg.leave(@scope, formula_name, pid)

  @doc """
  Dispatch the event to all subscribers.
  """
  @spec dispatch(event :: event()) :: :ok
  def dispatch({:code_change, formula_name, _old_code, _new_code} = event),
    do: do_dispatch(formula_name, event)

  def dispatch({:compiled, formula_name, _code, _opts} = event),
    do: do_dispatch(formula_name, event)

  def dispatch({:compile_failed, formula_name, _err, _code, _opts} = event),
    do: do_dispatch(formula_name, event)

  defp do_dispatch(formula_name, event),
    do:
      :pg.get_local_members(@scope, formula_name)
      |> Enum.each(&send(&1, event))

  @doc """
  Shortcut to `dispatch({:code_change, formula_name, old_code, new_code})`
  """
  @spec dispatch_code_change(formula_name(), old_code :: code(), new_code :: code()) :: :ok
  def dispatch_code_change(formula_name, old_code, new_code) do
    dispatch({:code_change, formula_name, old_code, new_code})
  end

  @impl true
  def init(_args) do
    case :pg.start(@scope) do
      {:ok, _pid} ->
        {:ok, nil}

      {:error, {:already_started, _pid}} ->
        {:ok, nil}

      {:error, _reason} = err ->
        err
    end
  end
end
