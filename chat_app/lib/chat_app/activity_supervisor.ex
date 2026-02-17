defmodule ChatApp.ActivitySupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_activity_server(username) do
    child_spec = {ChatApp.ActivityServer, username}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
