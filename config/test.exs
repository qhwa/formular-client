import Config

config :phoenix, :json_library, Jason

config :formular_client, TestSite.Endpoint,
  https: false,
  secret_key_base: String.duplicate("abcdefgh", 8),
  pubsub_server: TestSite.PubSub,
  debug_errors: true,
  server: true
