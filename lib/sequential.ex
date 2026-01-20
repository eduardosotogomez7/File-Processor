defmodule FileProcessor.Sequential do
  def process(path) when is_bitstring(path) do
    case String.trim(path) do
      "" ->
        {:error, "Path can not be empty"}

      _ ->
        path
        |> fileExists?()
        |> obtainDetails()
        |> obtainReport()
    end
  end

  def process([]) do
    {:warning, "No files to process"}
  end

  def process(files) when is_list(files) do
    case Enum.all?(files, &is_bitstring/1) do
      true ->
        Enum.map(files, &process/1)

      false ->
        {:error, "Invalid list. All elements must be file paths as strings."}
    end
  end

  def process(_) do
    {:error, "Invalid input. Expected a file path as a string or a list of file paths."}
  end

  defp fileExists?(path) do
    case File.exists?(path) do
      true -> {:ok, path}
      false -> {:error, "File not found"}
    end
  end

  defp obtainDetails({:error, _} = error) do
    error
  end

  defp obtainDetails({:ok, path}) do
    cond do
      File.regular?(path) -> {:file, Path.extname(path), path}
      File.dir?(path) -> {:dir, path}
    end
  end

  defp obtainReport({:file, ".csv", path}) do
    case FileProcessor.Handler.CSV.process(path) do
      {:ok, final_path} -> {:ok, :csv, final_path}
      {:partial, _} -> {:partial, :csv, path}
      {:error, _} -> {:error, :csv, path}
    end
  end

  defp obtainReport({:file, ".json", path}) do

    case FileProcessor.Handler.JSON.process(path) do
      {:ok, final_path} -> {:ok, :json, final_path}
      {:partial, _} -> {:partial, :json, path}
      {:error, _} -> {:error, :json, path}
    end

  end

  defp obtainReport({:file, ".log", path}) do
    case FileProcessor.Handler.LOG.process(path) do
      {:ok, final_path} -> {:ok, :log, final_path}
      {:partial, _} -> {:partial, :log, path}
      {:error, _} -> {:error, :log, path}
    end
  end

  defp obtainReport({:file, _, path}) do
    {:error, "Extension not allowed", path}
  end

  defp obtainReport({:dir, path}) do
    case File.ls(path) do
      {:ok, []} ->
        {:warning, "The directory is empty"}

        {:ok, _} ->
          process_directory(path)
      end




  end

  defp obtainReport({:error, _} = error) do
    error
  end

  defp process_directory(path) do
    case File.ls(path) do
      {:ok, []} ->
        {:warning, "The Directory is Empty"}

      {:ok, files} ->
        files
        |> Enum.map(fn x -> Path.join(path, x) end)
        |> Enum.map(fn file ->
          cond do
            File.regular?(file) -> process(file)
            File.dir?(file) -> process_directory(file)
            true ->
              {:error, "Unsoported file type: #{file}"}
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
