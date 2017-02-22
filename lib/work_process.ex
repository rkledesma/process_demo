defmodule Web.WorkProcess do
  use GenServer, otp_app: :web
  alias Web.{Work, Worker}

  @moduledoc """
  Genserver to represent a work process. ids are used to register processes so they can be looked up later
  """

  @work_registry_name :work_process_registry

  defstruct work: nil,
            work_pid: nil


  def start_link(id) do
    GenServer.start_link(__MODULE__, [id], [name: via_tuple(id)])
  end

  # registry lookup handler
  defp via_tuple(id), do: {:via, Registry, {@work_registry_name, id}}

  def start_work(id) do
    GenServer.cast(via_tuple(id), :set_timeout)
    GenServer.cast(via_tuple(id), :start_work)
  end

  def abort_work(id) do
    GenServer.cast(via_tuple(id), :abort_work)
  end

  def get_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end

  @doc """
  Returns the pid for the `id` process stored in the registry
  """
  def whereis(id) do
    case Registry.lookup(@work_registry_name, id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def init([id]) do
    work = Work.new(%{id: id, status: "running", data: ""})
    {:ok, %__MODULE__{work: work}}
  end

  def handle_cast(:set_timeout, state) do
    Process.send_after(self(), {:end_work, "Work timed out"}, 100000)
    {:noreply, state}
  end

  def handle_cast(:start_work, %{work: work} = state) do
    task = Task.async(fn -> Worker.start_work(work) end)
    {:noreply, %{state | work_pid: task.pid}}
  end

  def handle_cast(:abort_work, state) do
    send(self(), {:end_work, "Work manually aborted"})
    {:noreply, state}
  end

  def handle_call(:get_state, _from, state) do
    formatted_state = state.work
    {:reply, formatted_state, state}
  end

  def handle_info({:end_work, message}, %{work: work, work_pid: nil} = state) do
    Worker.exit_work(1, work, message, "success")
    {:noreply, state}
  end

  def handle_info({:end_work, message}, %{work_pid: pid} = state) do
    send(pid, {:exit_abort, message})
    {:noreply, state}
  end

  def handle_info({:end_process, _}, state) do
    {:stop, :normal, state}
  end
end
