import Config

config :queue_service, port: 3000
config :queue_service, base_folder: "./persist/dev/"
config :queue_service, consumer_route: "localhost:7000/simulate-busy"
