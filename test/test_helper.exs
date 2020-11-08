Supervisor.start_link(
  [Test.EchoServer],
  strategy: :one_for_one,
  max_restarts: 10,
  name: TestSupervisor
)

ExUnit.start()
