defmodule Queue do
  defstruct data: :queue.new(),
            length: 0

  def new() do
    %Queue{}
  end

  def add(%Queue{data: current_data, length: current_length}, event_data) do
    new_data = :queue.in(event_data, current_data)
    new_length = current_length + 1

    %Queue{data: new_data, length: new_length}
  end

  def remove(%Queue{data: current_data, length: current_length}) do
    {_, new_data} = :queue.out(current_data)
    new_length = max(0, current_length - 1)

    %Queue{data: new_data, length: new_length}
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
