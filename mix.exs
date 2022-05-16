defmodule Formular.Client.MixProject do
  use Mix.Project

  def project do
    [
      app: :formular_client,
      description:
        "Watch and fetch application's configuration from a server, and compile them into Elixir modules.",
      version: "0.2.1",
      elixir: ">= 1.10.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.json": :test,
        "coveralls.post": :test,
        "coveralls.github": :test,
        "coveralls.html": :test
      ],
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14.5", only: :test, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.6", only: :test},
      {:cowboy, "~> 2.0", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test}
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
