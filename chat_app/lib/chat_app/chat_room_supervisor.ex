defmodule ChatApp.ChatRoomSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_chatroom(state) do
    child_spec = {ChatApp.ChatRoomServer, state}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
