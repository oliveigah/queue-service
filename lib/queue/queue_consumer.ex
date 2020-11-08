defmodule Queue.Consumer do
  use GenServer

  @consumer_route Application.compile_env!(:queue_service, :consumer_route)
  @base_headers [
    {"Content-Type", "Application/json"},
    {"Accept", "Application/json"}
  ]
  @success_codes %{
    200 => true
  }

  def init(queue_id) do
    pid = Queue.Cache.server_process(queue_id)
    {:ok, pid}
  end

  def start_link(queue_id) do
    GenServer.start_link(__MODULE__, queue_id, name: via_tuple(queue_id))
  end

  def handle_info(:consume, queue_pid) do
    case Queue.Server.get(queue_pid) do
      {:ok, event, _} ->
        case http_post(event) do
          {:ok, _} ->
            {:ok, _} = Queue.Server.remove(queue_pid)

          _ ->
            nil
        end

      :empty ->
        nil
    end

    {:noreply, queue_pid}
  end

  defp http_post(data, headers \\ @base_headers) do
    {:ok, body} = Poison.encode(data)

    post_result = HTTPoison.post(@consumer_route, body, headers, recv_timeout: :timer.seconds(20))

    case post_result do
      {:ok, http_result} ->
        status_code = Map.get(http_result, :status_code, 500)
        decoded_body = Poison.decode(Map.get(http_result, :body))

        case decoded_body do
          {:ok, result_body} ->
            if(Map.get(@success_codes, status_code, false)) do
              {:ok, result_body}
            else
              {:error, result_body}
            end

          _ ->
            {:error, "Unknown"}
        end

      _ ->
        {:error, "Unknown"}
    end
  end

  defp via_tuple(id) do
    Queue.ProcessRegistry.via_tuple({__MODULE__, id})
  end
end
