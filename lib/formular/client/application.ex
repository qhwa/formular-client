defmodule Formular.Client.Application do
  use Application

  def start(_type, _args) do
    children = [
      Formular.Client.Compiler,
      Formular.Client.Cache,
      {DynamicSupervisor, name: Formular.Client.Instances, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
