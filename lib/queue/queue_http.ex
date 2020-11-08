defmodule Queue.Http do
  @moduledoc false
  use Plug.Router
  use Plug.ErrorHandler

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  def child_spec(_arg) do
    port = Application.fetch_env!(:queue_service, :port)

    if Application.get_env(:queue_service, :environment) !== :test do
      IO.puts("Queue service running on localhost:#{port}/event")
    end

    Plug.Adapters.Cowboy.child_spec(
      scheme: :http,
      options: [port: port],
      plug: __MODULE__
    )
  end

  defp send_http_response({status_code, response_body}, conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status_code, Poison.encode!(response_body))
  end

  defp format_response(result) do
    case result do
      {:ok, queue_length} ->
        {
          200,
          %{
            success: true,
            queue_length: queue_length
          }
        }

      _ ->
        {
          500,
          %{
            success: false,
            message: "Unknown"
          }
        }
    end
  end

  post("event") do
    Map.get(conn.body_params, "id")
    |> Queue.Cache.server_process()
    |> Queue.Server.add(conn.body_params)
    |> format_response
    |> send_http_response(conn)
  end
end
