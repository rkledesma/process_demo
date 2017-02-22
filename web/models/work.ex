defmodule Web.Work do
  @moduledoc """
  """
  defstruct [:id, :data, :status]
  alias Web.{WorkSupervisor, WorkProcess}

  def new(params) do
    struct(__MODULE__, params)
  end

  def get(id) do
    if WorkSupervisor.work_process_exists?(id) do
     WorkProcess.get_state(id)
   end
  end

  def list() do
    WorkSupervisor.ids()
  end

  def in_progress(id) do
    WorkSupervisor.work_process_exists?(id)
  end
end
