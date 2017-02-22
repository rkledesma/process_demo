defmodule Web.WorkChannel do
  @moduledoc """
  Channel for streaming work information
  """
  
  use Web.Web, :channel
  alias Web.{Endpoint}

  def join("work:" <> id, _payload, socket) do
    {:ok, "Joined work:#{id}", socket}
  end

  def broadcast_change(work) do
    Endpoint.broadcast("work:#{work.id}", "change", work)
  end
end
