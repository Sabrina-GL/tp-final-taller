defmodule ChatApp.FileManagerTest do
  use ExUnit.Case, async: false

  alias ChatApp.FileManager

  test "save_file/3 guarda archivo válido y retorna metadata" do
    content = "hola archivo"
    base64 = Base.encode64(content)

    assert {:ok, %{path: relative_path, size: size}} =
             FileManager.save_file(base64, "mi archivo.txt", "text/plain")

    assert size == byte_size(content)
    assert String.starts_with?(relative_path, "uploads/")

    absolute_path = FileManager.get_file_path(relative_path)
    assert File.exists?(absolute_path)
    assert File.read!(absolute_path) == content

    assert :ok = FileManager.delete_file(relative_path)
  end

  test "save_file/3 rechaza mime type no soportado" do
    base64 = Base.encode64("contenido")

    assert {:error, reason} =
             FileManager.save_file(base64, "mal.bin", "application/octet-stream")

    assert String.contains?(reason, "Unsupported file type")
  end

  test "save_file/3 rechaza base64 inválido" do
    assert {:error, "Invalid base64 encoding"} =
             FileManager.save_file("***invalid***", "archivo.txt", "text/plain")
  end

  test "save_file/3 rechaza archivo por tamaño" do
    oversized = :binary.copy("a", FileManager.max_file_size() + 1)
    base64 = Base.encode64(oversized)

    assert {:error, reason} = FileManager.save_file(base64, "big.txt", "text/plain")
    assert String.contains?(reason, "exceeds maximum allowed")
  end

  test "get_file_path/1 ignora path traversal y usa basename" do
    path = FileManager.get_file_path("uploads/../secreto.txt")
    assert String.ends_with?(path, "/priv/uploads/secreto.txt")
  end

  test "delete_file/1 elimina archivo existente" do
    base64 = Base.encode64("borrar")

    assert {:ok, %{path: relative_path}} =
             FileManager.save_file(base64, "delete_me.txt", "text/plain")

    absolute_path = FileManager.get_file_path(relative_path)
    assert File.exists?(absolute_path)

    assert :ok = FileManager.delete_file(relative_path)
    refute File.exists?(absolute_path)
  end

  test "delete_file/1 sobre archivo inexistente retorna :ok" do
    assert :ok = FileManager.delete_file("uploads/no_existe.txt")
  end

  test "delete_file/1 con nil retorna :ok" do
    assert :ok = FileManager.delete_file(nil)
  end

  test "allowed_mime_types/0 incluye tipos esperados" do
    allowed = FileManager.allowed_mime_types()

    assert "text/plain" in allowed
    assert "image/png" in allowed
    assert "application/pdf" in allowed
  end

end
