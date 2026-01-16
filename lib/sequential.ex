defmodule FileProcessor.Sequential do
  def process(path) when is_bitstring(path) do
    path
    |> fileExists?()
    |> obtainDetails()
    |> obtainReport()
  end



  def process([]) do
    {:warning, "No files to process"}
  end



  def process(files) when is_list(files) do
      files
      |> Enum.map(fn x -> process(x) end)
  end


  def process(_) do
    {:error, "Mensaje de error"}
  end

  defp fileExists?(path) do
    case File.exists?(path) do
      true -> {:ok, path}
      false -> {:error, "File not found"}
    end
  end



  defp obtainDetails({:error,_} = error) do
    error
  end

  defp obtainDetails({:ok,path}) do
    cond do
      File.regular?(path) -> {:file, Path.extname(path), path}

      File.dir?(path) -> {:dir, path}
    end
  end

  defp obtainReport({:file, ".csv", path}) do
    FileProcessor.Handler.CSV.process(path)
    {:ok, :csv}
  end

  defp obtainReport({:file, ".json", path}) do
    FileProcessor.Handler.JSON.process(path)
    {:ok, :json}
  end

  defp obtainReport({:file, ".log", path}) do
    FileProcessor.Handler.LOG.process(path)
    {:ok, :log}
  end

  defp obtainReport({:file, _, _}) do
    {:error, "Extension no permitida"}
  end

  defp obtainReport({:dir, path}) do
    process_directory(path)
    {:ok, "Directorio"}
  end

  defp obtainReport({:error,_} = error) do
    error
  end

  defp process_directory(path) do
    case File.ls(path) do
      {:ok, []} -> {:warning, "The Directory is Empty"}

      {:ok, files} ->
        files
        |> Enum.map(fn x -> Path.join(path,x) end)
        |> Enum.map(fn file ->
          cond do
            File.regular?(file) -> process(file)

            File.dir?(file) -> process_directory(file)

            true -> {:error, "Unsoported file type: #{file}"}

          end
        end)


      {:error, reason} -> {:error, reason}
    end
  end
end
