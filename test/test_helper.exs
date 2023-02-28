Phoenix.PubSub.Supervisor.start_link(
  adapter: Phoenix.PubSub.PG2,
  name: TestSite.PubSub
)

port = 1500

{:ok, _pid} = TestSite.Endpoint.start_link(http: [port: port])

ExUnit.start()
