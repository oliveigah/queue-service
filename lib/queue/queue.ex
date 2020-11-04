defmodule Queue do
  defstruct data: :queue.new(),
            length: 0,
            id: "default"

  def new(id) do
    %Queue{id: id}
  end

  def add(%Queue{data: current_data, length: current_length} = queue, event_data) do
    new_data = :queue.in(event_data, current_data)
    new_length = current_length + 1

    queue
    |> Map.put(:data, new_data)
    |> Map.put(:length, new_length)
  end

  def remove(%Queue{data: current_data, length: current_length} = queue) do
    {_, new_data} = :queue.out(current_data)
    new_length = max(0, current_length - 1)

    queue
    |> Map.put(:data, new_data)
    |> Map.put(:length, new_length)
  end

  def get(%Queue{length: 0}) do
    {:empty, nil}
  end

  def get(%Queue{data: data}) do
    {:ok, :queue.get(data)}
  end

  def length(%Queue{} = q) do
    q.length
  end
end
