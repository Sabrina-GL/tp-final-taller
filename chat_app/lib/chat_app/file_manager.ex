defmodule ChatApp.FileManager do
  @moduledoc """
  Manages file uploads and downloads for chat messages.
  Files are stored in priv/uploads/ with UUID-based filenames.
  """

  @upload_dir "priv/uploads"
  @max_file_size 5_242_880  # 5MB in bytes

  @allowed_mime_types [
    # Images
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/gif",
    "image/webp",
    # Documents
    "application/pdf",
    "text/plain",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  ]

  @doc """
  Saves a base64-encoded file to disk.

  Returns {:ok, %{path: relative_path, size: size_in_bytes}} or {:error, reason}

  ## Examples

      iex> save_file("aGVsbG8=", "hello.txt", "text/plain")
      {:ok, %{path: "uploads/abc-123-hello.txt", size: 5}}
  """
  def save_file(base64_content, original_filename, mime_type) do
    with :ok <- validate_mime_type(mime_type),
         {:ok, binary_content} <- decode_base64(base64_content),
         :ok <- validate_file_size(binary_content),
         :ok <- ensure_upload_dir(),
         {:ok, file_path} <- write_file(binary_content, original_filename) do
      {:ok, %{path: file_path, size: byte_size(binary_content)}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the absolute path for a relative file path.

  ## Examples

      iex> get_file_path("uploads/abc-123-hello.txt")
      "/absolute/path/priv/uploads/abc-123-hello.txt"
  """
  def get_file_path(relative_path) do
    Path.join([File.cwd!(), @upload_dir, Path.basename(relative_path)])
  end

  @doc """
  Deletes a file from disk.

  Returns :ok or {:error, reason}

  ## Examples

      iex> delete_file("uploads/abc-123-hello.txt")
      :ok
  """
  def delete_file(relative_path) when is_binary(relative_path) do
    file_path = get_file_path(relative_path)

    if File.exists?(file_path) do
      case File.rm(file_path) do
        :ok -> :ok
        {:error, reason} -> {:error, "Failed to delete file: #{reason}"}
      end
    else
      :ok  # File doesn't exist, consider it deleted
    end
  end

  def delete_file(nil), do: :ok

  # Private functions

  defp validate_mime_type(mime_type) when mime_type in @allowed_mime_types, do: :ok
  defp validate_mime_type(mime_type), do: {:error, "Unsupported file type: #{mime_type}"}

  defp decode_base64(base64_content) do
    case Base.decode64(base64_content) do
      {:ok, binary} -> {:ok, binary}
      :error -> {:error, "Invalid base64 encoding"}
    end
  end

  defp validate_file_size(binary_content) do
    size = byte_size(binary_content)

    if size <= @max_file_size do
      :ok
    else
      {:error, "File size (#{size} bytes) exceeds maximum allowed (#{@max_file_size} bytes)"}
    end
  end

  defp ensure_upload_dir do
    upload_path = Path.join([File.cwd!(), @upload_dir])

    case File.mkdir_p(upload_path) do
      :ok -> :ok
      {:error, reason} -> {:error, "Failed to create upload directory: #{reason}"}
    end
  end

  defp write_file(binary_content, original_filename) do
    # Generate unique ID using Ecto.UUID
    unique_id = Ecto.UUID.generate()
    safe_filename = sanitize_filename(original_filename)
    filename = "#{unique_id}-#{safe_filename}"

    file_path = Path.join([File.cwd!(), @upload_dir, filename])

    case File.write(file_path, binary_content) do
      :ok -> {:ok, "uploads/#{filename}"}
      {:error, reason} -> {:error, "Failed to write file: #{reason}"}
    end
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    |> String.slice(0, 200)  # Limit filename length
  end

  @doc """
  Returns the maximum allowed file size in bytes.
  """
  def max_file_size, do: @max_file_size

  @doc """
  Returns list of allowed MIME types.
  """
  def allowed_mime_types, do: @allowed_mime_types
end
