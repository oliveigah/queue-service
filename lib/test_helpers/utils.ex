defmodule Test.QueueSystem do
  def reset() do
    # Get the pids of all currently alive processes
    queue_used_pids =
      DynamicSupervisor.which_children(Queue.Cache)
      |> Stream.map(fn entry ->
        case entry do
          {_, pid, :worker, [Queue.Server]} -> pid
          _ -> nil
        end
      end)
      |> Enum.filter(fn ele -> ele !== nil end)

    # Terminate all processes
    Enum.each(queue_used_pids, &send(&1, :timeout))

    # Reset the "database"
    base_folder = Application.get_env(:queue_service, :base_folder)
    File.rm_rf(base_folder)
    :ok
  end
end
