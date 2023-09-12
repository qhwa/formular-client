defmodule Formular.Client.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Formular.Client.Compiler.Supervisor,
      Formular.Client.Cache,
      Formular.Client.PubSub,
      {DynamicSupervisor, name: Formular.Client.Instances, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
