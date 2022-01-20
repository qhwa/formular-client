defmodule Formular.Client.MixProject do
  use Mix.Project

  def project do
    [
      app: :formular_client,
      description:
        "Watch and fetch application's configuration from a server, and compile them into Elixir modules.",
      version: "0.1.0-alpha.1",
      elixir: ">= 1.12.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
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
      {:phoenix_gen_socket_client, "~> 4.0"},
      {:websocket_client, "~> 1.4"},
      {:jason, "~> 1.2"},
      {:formular, "~> 0.3.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: [
        "qhwa <qhwa@pnq.cc>"
      ],
      source_url: "https://github.com/qhwa/formular-client",
      links: %{
        Github: "https://github.com/qhwa/formular-client"
      },
      files: ~w[
        lib mix.exs
      ]
    ]
  end
end
