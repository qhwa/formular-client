defmodule Formular.Client.Supervisor do
  @moduledoc """
  Supervisor for a Formular client.
  """

  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config)
  end

  @impl true
  def init(config) do
    children = [
      {Formular.Client.Listener, config}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
