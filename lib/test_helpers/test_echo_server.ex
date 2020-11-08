defmodule Test.EchoServer do
  @moduledoc false
  use Plug.Router
  use Plug.ErrorHandler

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  def child_spec(_arg) do
    port = Application.fetch_env!(:queue_service, :consumer_server_port)

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
    if Map.get(result, "fail") do
      {
        500,
        %{
          success: false,
          message: "Unknown"
        }
      }
    else
      {
        200,
        result
      }
    end
  end

  post("echo") do
    conn.body_params
    |> format_response()
    |> send_http_response(conn)
  end
end
