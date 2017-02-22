defmodule Web.WorkSupervisor do
  use Supervisor
  alias Web.WorkProcess

  @moduledoc """
  Supervisor to create/register and access existing WorkProcess processes via their ids
  """

  @work_registry_name :work_process_registry
  @sleep_duration 10

  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def find_or_create_process(id) do
    if work_process_exists?(id) do
      {:ok}
    else
      id |> create_work_process
    end
  end

  def create_process(id) do
    if work_process_exists?(id) do
      {:error, :process_already_exists}
    else
      id |> create_work_process
    end
  end

  def work_process_exists?(id) do
    if Registry.lookup(@work_registry_name, id) == [], do: false, else: true
  end

  defp create_work_process(id) do
    case Supervisor.start_child(__MODULE__, [id]) do
      {:ok, _pid} -> {:ok}
      {:error, {:already_started, _pid}} -> {:error, :process_already_exists}
      other -> {:error, other}
    end
  end

  def end_process(id) do
    Registry.dispatch(@work_registry_name, id, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:end_process, ""})
    end)
  end

  def work_process_count, do: Supervisor.which_children(__MODULE__) |> length

  def ids do
    ids = Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, work_proc_pid, _, _} ->
      Registry.keys(@work_registry_name, work_proc_pid)
      |> List.first
    end)
    |> Enum.sort
    ids || []
  end

  @doc """
  Used only by unit tests to ensure asynchronous processes are completed before moving on
  """
  def wait_for_children, do: wait_for_children(ids())
  defp wait_for_children([]), do: nil
  defp wait_for_children(_ids) do
    Process.sleep(@sleep_duration)
    wait_for_children(ids())
  end

  def init(_) do
    children = [
      worker(Web.WorkProcess, [], restart: :temporary)
    ]

    # strategy set to `:simple_one_for_one` to handle dynamic child processes.
    supervise(children, strategy: :simple_one_for_one)
  end
end
