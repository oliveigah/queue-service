defmodule Queue.Server do
  use GenServer

  @messages_folder "messages"
  @idle_timeout :timer.minutes(2)

  @impl GenServer
  def init(id) do
    send(self(), {:real_init, id})
    {:ok, nil}
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
  def handle_call({:add, event_data}, _from, %Queue{} = current_state) do
    new_state = Queue.add(current_state, event_data)
    {:reply, {:ok, new_state.length}, new_state}
  end

  def handle_call(:remove, _from, %Queue{} = current_state) do
    new_state = Queue.remove(current_state)
    {:reply, {:ok, new_state.length}, new_state}
  end

  def handle_call(:get, _from, %Queue{} = current_state) do
    case Queue.get(current_state) do
      {:ok, event} ->
        {:reply, {:ok, event, current_state.length}, current_state}

      {:empty, nil} ->
        {:reply, :empty, current_state}
    end
  end

  ## -------- Handle Info --------
  @impl GenServer
  def handle_info({:real_init, id}, _state) do
    case FileDatabase.get(id, @messages_folder) do
      nil ->
        new_queue = Queue.new()
        {:noreply, new_queue, @idle_timeout}

      data ->
        {:noreply, data, @idle_timeout}
    end
  end

  ## -------- Private Functions --------

  defp via_tuple(id) do
    Queue.ProcessRegistry.via_tuple(id)
  end
end
