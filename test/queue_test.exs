defmodule QueueTest do
  use ExUnit.Case

  doctest Queue

  test "queue structure" do
    q =
      Queue.new()
      |> Queue.add("event 1")
      |> Queue.add("event 2")
      |> Queue.add("event 3")

    assert Queue.length(q) == 3
    assert Queue.get(q) == {:ok, "event 1"}

    q = Queue.remove(q)

    assert Queue.length(q) == 2
    assert Queue.get(q) == {:ok, "event 2"}

    q = Queue.remove(q)

    assert Queue.length(q) == 1
    assert Queue.get(q) == {:ok, "event 3"}

    q = Queue.remove(q)

    assert Queue.length(q) == 0
    assert Queue.get(q) == {:empty, nil}
  end
end
