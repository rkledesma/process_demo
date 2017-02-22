defmodule Web.WorkController do
  use Web.Web, :controller
  alias Web.{Work, WorkSupervisor,WorkProcess}

  def index(conn, _params) do
    work_ids = Work.list()
    render(conn, "index.html", work_ids: work_ids)
  end


  def new(conn, _params) do
    render(conn,"new.html")
  end


  def create(conn, %{"id" => id}) do
    id = String.to_integer(id)
    if WorkSupervisor.work_process_exists?(id) do
      send_resp(conn, 423, "Error: process exists!")
    else
      WorkSupervisor.create_process(id)
      WorkProcess.start_work(id)
      show(conn, %{"id" => id})
    end
  end

  def abort(conn, %{"id" => id}) do
    id = String.to_integer(id)
    if Web.WorkSupervisor.work_process_exists?(id) do
      Web.WorkProcess.abort_work(id)
      send_resp(conn, 200, "OK")
    else
      send_resp(conn, 423, "Error: could not find process")
    end
  end

  def show(conn, %{"id" => id}) do
    id =
    case is_binary(id) do
      true -> String.to_integer(id)
      _ -> id
    end

    work = Work.get(id)
    if work do
      render(conn, "show.html", work: work)
    else
      conn
        |> put_status(:not_found)
        |> render(Web.ErrorView, "404.html")
    end
  end
end
