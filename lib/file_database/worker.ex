defmodule FileDatabase.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def store_async(pid, key, data, folder) do
    File.mkdir_p!(folder)
    GenServer.cast(pid, {:store, key, data, folder})
  end

  def store_sync(pid, key, data, folder) do
    File.mkdir_p!(folder)
    GenServer.call(pid, {:store, key, data, folder})
  end

  def get(pid, key, folder) do
    GenServer.call(pid, {:get, key, folder})
  end

  def init(_) do
    {:ok, nil}
  end

  defp file_name(folder_path, key) do
    Path.join(folder_path, to_string(key))
  end

  @doc false
  def handle_cast({:store, key, value, folder_path}, _state) do
    file_name(folder_path, key)
    |> File.write!(:erlang.term_to_binary(value))

    {:noreply, nil}
  end

  @doc false
  def handle_call({:get, key, folder_path}, _from, _state) do
    response =
      case File.read(file_name(folder_path, key)) do
        {:ok, data} -> :erlang.binary_to_term(data)
        _ -> nil
      end

    {:reply, response, nil}
  end

  @doc false
  def handle_call({:store, key, value, folder_path}, _from, _state) do
    result =
      file_name(folder_path, key)
      |> File.write!(:erlang.term_to_binary(value))

    {:reply, result, nil}
  end
end
