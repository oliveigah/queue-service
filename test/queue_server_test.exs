defmodule QueueServerTest do
  use ExUnit.Case

  doctest Queue.Server

  setup do
    Test.QueueSystem.reset()
  end

  test "queue consumption" do
    q = Queue.Cache.server_process("a")

    Queue.Server.add(q, %{fail: false})
    Queue.Server.add(q, %{fail: false})
    Queue.Server.add(q, %{fail: false})

    Process.sleep(:timer.seconds(1))

    assert Queue.Server.get(q) == :empty
  end

  test "queue id independency" do
    q1 = Queue.Cache.server_process("a")
    q2 = Queue.Cache.server_process("b")

    Queue.Server.add(q1, %{fail: false})
    Queue.Server.add(q1, %{fail: true})
    Queue.Server.add(q1, %{fail: false})
    Queue.Server.add(q1, %{fail: false})

    Queue.Server.add(q2, %{fail: false})
    Queue.Server.add(q2, %{fail: false})
    Queue.Server.add(q2, %{fail: false})
    Queue.Server.add(q2, %{fail: false})
    Queue.Server.add(q2, %{fail: false})

    Process.sleep(:timer.seconds(1))

    assert Queue.Server.get(q1) == {:ok, %{fail: true}, 3}
    assert Queue.Server.get(q2) == :empty
  end
end
