defmodule Queue.Server do
  use GenServer, restart: :temporary

  @messages_folder "messages"
  @idle_timeout :timer.seconds(15)

  @impl GenServer
  def init(id) do
    send(self(), {:real_init, id})
    {:ok, nil, @idle_timeout}
  end

  ## -------- Public Interface --------
  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def add(pid, event_data) do
    GenServer.call(pid, {:add, event_data})
  end

  def remove(pid) do
    GenServer.call(pid, :remove)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  ## -------- Handle Call --------
  @impl GenServer
  def handle_call({:add, event_data}, _from, %Queue{id: id} = current_state) do
    new_state = Queue.add(current_state, event_data)
    persist_event(new_state)

    request_consumer(id)

    {:reply, {:ok, new_state.length}, new_state, @idle_timeout}
  end

  def handle_call(:remove, _from, %Queue{id: id} = current_state) do
    new_state = Queue.remove(current_state)
    persist_event(new_state)

    if new_state.length > 0, do: request_consumer(id)

    {:reply, {:ok, new_state.length}, new_state, @idle_timeout}
  end

  def handle_call(:get, _from, %Queue{} = current_state) do
    case Queue.get(current_state) do
      {:ok, event} ->
        {:reply, {:ok, event, current_state.length}, current_state, @idle_timeout}

      {:empty, nil} ->
        {:reply, :empty, current_state, @idle_timeout}
    end
  end

  ## -------- Handle Info --------
  @impl GenServer
  def handle_info({:real_init, id}, _state) do
    start_consumer(id)

    case FileDatabase.get(id, @messages_folder) do
      nil ->
        new_queue = Queue.new(id)
        FileDatabase.store_sync(id, new_queue, @messages_folder)
        {:noreply, new_queue, @idle_timeout}

      data ->
        request_consumer(id)
        {:noreply, data, @idle_timeout}
    end
  end

  def handle_info(:timeout, %Queue{} = state) do
    {:stop, :normal, state}
  end

  @impl GenServer
  def terminate(_reason, %Queue{length: current_length, id: id}) do
    if current_length <= 0 do
      FileDatabase.delete(id, @messages_folder)
    end
  end

  ## -------- Private Functions --------

  defp via_tuple(id) do
    Queue.ProcessRegistry.via_tuple({__MODULE__, id})
  end

  defp start_consumer(id) do
    children = [
      %{
        id: Queue.Consumer,
        start: {Queue.Consumer, :start_link, [id]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp request_consumer(id) do
    [{consumer_pid, _}] = Registry.lookup(Queue.ProcessRegistry, {Queue.Consumer, id})
    send(consumer_pid, :consume)
  end

  defp persist_event(%Queue{id: id} = state) do
    FileDatabase.store_sync(id, state, @messages_folder)
  end
end
