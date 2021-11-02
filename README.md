# Formular.Client

## Getting Start

1. Install dependency

    Add `{:formular_client, github: "zubale/formular-client"}` to `deps` section of `mix.exs`

2. Config client

    Add formular client into the supervision tree:

    ```elixir
    # file: lib/myapp/application.ex
    
    defmodule Myapp.Application do
      use Application

      def start(_type, _args) do
        children = [
          ...
          {Formular.Client.Supervisor, formular_client_config()},
          ...
        ]

        opts = [strategy: :one_for_one, name: QuestService.Supervisor]
        Supervisor.start_link(children, opts)
      end

      defp formular_client_config do
        url: "wss://example.com/socket/websocket",
        formulas: [
          # {key, module, context_module}
          {"batching", BatchingFormular, nil}
        ]
      end
    end
    ```

    where `url` points to a formular server.

3. Use it in your code

    ```elixir
    iex> BatchingFormular.run(store: %{id: "foo"})
    false
    ```


