defmodule QueueService.Application do
  @moduledoc false
  use Application

  def start(_, _) do
    QueueService.System.start_link()
  end
end
