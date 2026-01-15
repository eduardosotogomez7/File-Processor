defmodule FileProcessor.Parallel.Coordinator do

  def process_directory(path) when is_bitstring(path) do
    case File.ls(path) do
      {:ok, files} ->
        files
        |> Enum.map(fn x -> Path.join(path, x) end)
        |> process_files()
    end
  end

  def process_directory(path, options) when is_map(options) do
  case File.ls(path) do
    {:ok, files} ->
      files
      |> Enum.map(&Path.join(path, &1))
      |> process_files(options)
  end
end

def process_directory(_, _) do
  {:error, "Options must be a map"}
end


  def process_files(files) when is_list(files) do

    totalFiles = length(files)

    tasks =
      files
      |> Enum.with_index(1)
      |> Enum.map(fn {path, index} ->
        Task.async(fn ->
          result = FileProcessor.Sequential.process(path)
          IO.puts("[#{index} / #{totalFiles}] Procesado")
          result
        end)

      end)

    tasks
    |> Enum.map(fn task ->
      try do
        {:ok, Task.await(task, 5000)}
      catch
        :exit, {:timeout, _} -> {:error, :timeout}

        :exit, reason -> {:error, reason}
      end
    end)
  end

  def process_files(files, options) when is_list(files) do
  max_workers = Map.get(options, :max_workers, System.schedulers_online())
  timeout = Map.get(options, :timeout, 5000)

  files
  |> Task.async_stream(
    fn path ->
      FileProcessor.Sequential.process(path)
    end,
    max_concurrency: max_workers,
    timeout: timeout
  )
  |> Enum.to_list()
end



end
