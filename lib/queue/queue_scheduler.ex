defmodule Queue.Scheduler do
  @moduledoc """
  `GenServer` responsible for start the `Metrics.Collector` task every 5 minutes
  """
  use GenServer
  @interval_time :timer.seconds(30)
  @base_folder Application.compile_env!(:queue_service, :base_folder)
  @messages_folder "messages"
  @doc false
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_arg) do
    :timer.send_interval(@interval_time, self(), :start_non_empty_queues)
    {:ok, nil}
  end

  @doc false
  def handle_info(:start_non_empty_queues, _state) do
    non_empty_queues_id()
    |> Enum.each(&Queue.Cache.server_process/1)

    {:noreply, nil}
  end

  def non_empty_queues_id() do
    {:ok, list} = Path.Wildcard.list_dir("#{@base_folder}#{@messages_folder}")
    Enum.map(list, &List.to_integer/1)
  end
end
