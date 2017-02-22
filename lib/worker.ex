defmodule Web.Worker do
  @moduledoc"""
  """
  alias Web.{WorkChannel, WorkSupervisor}
  require Logger

  def start_work(work) do
    work
    |> run_shell_command
    |> handle_output(work, "")
  end

  def handle_output(port, work, message \\"") do
    receive do
      {^port, {:data, message}} ->
        work = %{work | data: message}
        WorkChannel.broadcast_change(work)
        handle_output(port, work, message)
      {^port, {:exit_status, status}} ->
        exit_work(status, work, message, status)
      {:exit_abort, message} ->
        exit_work(3, work, message, "aborted")
      _ ->
        # unknown message so assume failure
        exit_work(1, work, message, "failure")
    end
  end

  def exit_work(_exit_code, work, message, status) do
    work = %{work | data: message, status: status}
    WorkChannel.broadcast_change(work)
    WorkSupervisor.end_process(work.id)
  end

  defp run_shell_command(_work) do
    Port.open(
      {:spawn_executable, binary()},
      [{:args, []}, :stream, :binary, :exit_status, :hide, :use_stdio, :stderr_to_stdout]
    )
  end

  defp binary do
    Path.join("script", "do_work")
  end
end
