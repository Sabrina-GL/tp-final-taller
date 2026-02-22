defmodule ChatApp.ChatRoomSupervisor do
  @moduledoc """
  Supervisor dinámico para gestionar los GenServers de cada sala de chat.

  Este módulo se encarga de iniciar y supervisar un GenServer para cada sala de chat activa.
  Utiliza un DynamicSupervisor para permitir la creación dinámica de procesos a medida que se crean nuevas salas de chat.
  """
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
