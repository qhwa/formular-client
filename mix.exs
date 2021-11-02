defmodule Formular.Client.MixProject do
  use Mix.Project

  def project do
    [
      app: :formular_client,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Formular.Client.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:websockex, "~> 0.4"},
      {:jason, "~> 1.2"},
      {:formular, "~> 0.3"}
    ]
  end
end
