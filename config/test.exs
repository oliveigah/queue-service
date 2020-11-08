import Config

config :queue_service, port: 8000
config :queue_service, base_folder: "./persist/test/"
config :queue_service, consumer_route: "localhost:7999/echo"
config :queue_service, consumer_server_port: 7999
config :queue_service, environment: :test
