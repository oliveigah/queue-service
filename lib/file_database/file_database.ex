defmodule FileDatabase do
  @workers_count 3
  @base_folder Application.compile_env!(:queue_service, :base_folder)

  def child_spec(_) do
    File.mkdir_p!(@base_folder)

    :poolboy.child_spec(
      __MODULE__,
      name: {:local, __MODULE__},
      worker_module: FileDatabase.Worker,
      size: @workers_count
    )
  end

  defp concatenate_folder(folder) do
    "#{@base_folder}#{folder}"
  end

  def store_local_async(key, value, folder) do
    final_folder = concatenate_folder(folder)

    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        FileDatabase.Worker.store_async(worker_pid, key, value, final_folder)
      end
    )
  end

  def store_async(key, value, folder) do
    :erpc.multicast(
      Node.list([:this, :visible]),
      __MODULE__,
      :store_local_async,
      [key, value, folder]
    )

    :ok
  end

  def store_local_sync(key, value, folder) do
    final_folder = concatenate_folder(folder)

    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        FileDatabase.Worker.store_sync(worker_pid, key, value, final_folder)
      end
    )
  end

  def delete_local(key, folder) do
    final_folder = concatenate_folder(folder)

    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        FileDatabase.Worker.delete(worker_pid, key, final_folder)
      end
    )
  end

  def store_sync(key, value, folder) do
    :erpc.multicall(
      Node.list([:this, :visible]),
      __MODULE__,
      :store_local_sync,
      [key, value, folder],
      :timer.seconds(5)
    )

    :ok
  end

  def get(key, folder) do
    final_folder = concatenate_folder(folder)

    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        FileDatabase.Worker.get(worker_pid, key, final_folder)
      end
    )
  end

  def delete(key, folder) do
    :erpc.multicall(
      Node.list([:this, :visible]),
      __MODULE__,
      :delete_local,
      [key, folder],
      :timer.seconds(5)
    )
  end
end
