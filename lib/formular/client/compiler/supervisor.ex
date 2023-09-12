defmodule Formular.Client.Compiler.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      {Registry, keys: :unique, name: Formular.Client.Compiler.Registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
