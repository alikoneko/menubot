defmodule Menus.Registry do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: Menus.Registry)
  end

  def add(menu, meal) do
    GenServer.call(Menus.Registry, {:add, menu, meal})
  end

  def remove(menu, meal) do
    GenServer.call(Menus.Registry, {:remove, menu, meal})
  end

  def list(menu) do
    GenServer.call(Menus.Registry, {:list, menu})
  end

  def choose(menu) do
    GenServer.call(Menus.Registry, {:choose, menu})
  end

  def init(:ok) do
    {:ok, initial_state}
  end

  defp initial_state do
    File.mkdir("data")

    case File.read("data/state.json") do
      {:error, _}  -> %{}
      {:ok, state} -> Poison.decode!(state)
    end
  end

  def handle_call({:add, menu, meal}, _from, menus) do
    case add_meal(fetch_meals(menus, menu), meal) do
      {:added, meals} -> {:reply, {:ok, "#{meal} added to #{menu} options"}, save(Map.put(menus, menu, meals))}
      :already_exists -> {:reply, {:ok, "#{meal} already in #{menu} options"}, menus}
    end
  end

  defp add_meal([], meal) do
    {:added, [meal]}
  end

  defp add_meal(meals, meal) do
    case Enum.member?(meals, meal) do
      true  -> :already_exists
      false -> {:added, Enum.concat(meals, [meal])}
    end
  end

  def handle_call({:remove, menu, meal}, _from, menus) do
    case remove_meal(fetch_meals(menus, menu), meal) do
      {:removed, meals} -> {:reply, {:ok, "#{meal} removed from #{menu} options"}, save(filter(Map.put(menus, menu, meals)))}
      :not_found        -> {:reply, {:ok, "#{meal} is not in #{menu} options"}, menus}
    end
  end

  defp remove_meal([], _) do
    :not_found
  end

  defp remove_meal(meals, meal) do
    case Enum.member?(meals, meal) do
      true  -> {:removed, Enum.filter(meals, fn meal_to_check -> meal_to_check != meal end)}
      false -> :not_found
    end
  end

  def handle_call({:choose, menu}, _from, menus) do
    case make_choice(fetch_meals(menus, menu)) do
      :not_found    -> {:reply, {:error, "#{menu} has no meals - available options are #{availability(menus)}"}, menus}
      {:meal, meal} -> {:reply, {:ok, meal}, menus}
    end
  end

  defp make_choice([]) do
    :not_found
  end

  defp make_choice(meals) do
    {:meal, Enum.random(meals)}
  end

  def handle_call({:list, menu}, _from, menus) do
    {:reply, {:ok, fetch_meals(menus, menu)}, menus}
  end

  defp fetch_meals(menus, menu) do
    case Map.has_key?(menus, menu) do
      true -> menus[menu]
      false -> []
    end
  end

  defp availability(menus) do
    menus
    |> Map.keys
    |> Enum.sort
    |> Enum.join(", ")
  end

  defp save(menus) do
    :ok = File.write("data/state.json", Poison.encode!(menus))
    menus
  end

  defp filter(menus) do
    menus
    |> Enum.filter(fn {menu, meals} -> !Enum.empty?(meals) end)
    |> Map.new
  end
end
