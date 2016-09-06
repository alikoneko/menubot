defmodule Menus.MenusController do
  use Menus.Web, :controller

  def index(conn, params) do
    response = case params["text"] do
      "choose " <> menu -> choose(menu)
      "add " <> subcommand -> add(subcommand)
      "remove " <> subcommand -> remove(subcommand)
      _ -> valid_commands
    end

    json conn, response
  end

  def choose(menu) do
    case Menus.Registry.choose(Menus.Registry, menu) do
      {:ok, meal} -> %{"response_type" => "in_channel", "text" => "Why don't you have #{meal}?"}
      {:error, message} -> %{"response_type" => "in_channel", "text" => message}
    end
  end

  def add(subcommand) do
    [menu, meal] = split_subcommand(subcommand)
    {:ok, message} = Menus.Registry.add(Menus.Registry, menu, meal)
    %{"response_type" => "in_channel", "text" => message}
  end

  def remove(subcommand) do
    [menu, meal] = split_subcommand(subcommand)
    {:ok, message} = Menus.Registry.remove(Menus.Registry, menu, meal)
    %{"response_type" => "in_channel", "text" => message}
  end

  def valid_commands do
    %{"response_type" => "in_channel", "text" =>
      "Valid commands are `/menu choose [menu]`, `/menu add [menu] [option]`, and `/menu remove [menu] [option]`"
    }
  end

  defp split_subcommand(subcommand) do
    String.split(subcommand, " ", parts: 2)
  end
end
