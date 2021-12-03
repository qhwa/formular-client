defmodule Formular.Client.Application do
  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Formular.Client.Sockets, strategy: :one_for_one},
      Formular.Client.Cache
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
