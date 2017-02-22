defmodule Web.Router do
  use Web.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", Web do
    pipe_through :browser # Use the default browser stack

    get "/", WorkController, :index
    resources "/works", WorkController,
      only: [:new, :show, :index, :create]
    post "/works/:id/abort", WorkController, :abort
  end
end
