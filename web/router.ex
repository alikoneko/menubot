defmodule Menus.Router do
  use Menus.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/menus", Menus do
    pipe_through :api

    get "/", MenusController, :index
  end
end
