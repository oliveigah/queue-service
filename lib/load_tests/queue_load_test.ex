defmodule LoadTest.Queue do
  @doc """
  Executes the load test

  To run the test, use the following command:

  elixir -S mix run -e LoadTest.Queue.run
  """

  @events_quantity [
    10,
    100,
    1000,
    10_000,
    100_000
  ]
  def run do
    Queue.new("test")
    |> add_events(1)
    |> remove_events(1)

    Enum.each(@events_quantity, fn qty ->
      {add_time, queue} =
        :timer.tc(fn ->
          Queue.new("test")
          |> add_events(qty)
        end)

      {remove_time, _} =
        :timer.tc(fn ->
          queue
          |> remove_events(qty)
        end)

      IO.puts("#{qty} events | Add Time: #{add_time / 1000} ms")
      IO.puts("#{qty} events | Remove Time: #{remove_time / 1000} ms")
    end)
  end

  defp add_events(queue, qty) do
    Enum.reduce(1..qty, queue, fn index, queue_acc ->
      Queue.add(queue_acc, "event #{index}")
    end)
  end

  defp remove_events(queue, qty) do
    Enum.reduce(1..qty, queue, fn index, queue_acc ->
      event = "event #{index}"
      {:ok, ^event} = Queue.get(queue_acc)
      Queue.remove(queue_acc)
    end)
  end
end
