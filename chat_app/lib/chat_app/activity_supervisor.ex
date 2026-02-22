defmodule ChatApp.ActivitySupervisor do
  @moduledoc """
  Supervisor dinámico para gestionar los GenServers de actividad de cada usuario.

  Este módulo se encarga de iniciar y supervisar un GenServer de actividad para cada
  usuario que se conecta. Utiliza un DynamicSupervisor para permitir la creación
  dinámica de procesos a medida que los usuarios se conectan y desconectan.

  Estrategia de supervisión: :one_for_one, lo que significa que si un GenServer de
  actividad falla, solo ese proceso será reiniciado sin afectar a los demás.
  """
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
