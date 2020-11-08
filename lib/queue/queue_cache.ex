defmodule Queue.Cache do
  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  @doc false
  def start_link() do
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  @doc false
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  defp start_child(id) do
    DynamicSupervisor.start_child(__MODULE__, Queue.Server.child_spec(id))
  end

  defp is_already_running?(id) do
    case Registry.lookup(Queue.ProcessRegistry, {Queue.Server, id}) do
      [] ->
        false

      [{pid, _value}] ->
        {true, pid}
    end
  end

  def run_server_process(id) do
    case(is_already_running?(id)) do
      false ->
        {_, pid} = start_child(id)
        pid

      {true, pid} ->
        pid
    end
  end

  def server_process(id) do
    :rpc.call(
      find_node(id),
      __MODULE__,
      :run_server_process,
      [id]
    )
  end

  defp find_node(id) do
    nodes = Enum.sort(Node.list([:this, :visible]))

    node_index =
      :erlang.phash2(
        id,
        length(nodes)
      )

    Enum.at(nodes, node_index)
  end
end
