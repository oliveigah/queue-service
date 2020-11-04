defmodule QueueService.System do
  @moduledoc false
  def start_link() do
    Supervisor.start_link(
      [FileDatabase, Queue.ProcessRegistry, Queue.Cache],
      strategy: :one_for_one,
      max_restarts: 10,
      name: __MODULE__
    )
  end
end
