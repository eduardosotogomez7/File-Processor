defmodule FileProcessor.Parallel.Coordinator do
  @moduledoc """
  Coordinator module responsible for parallel file and directory processing.

  This module manages the execution of file processing tasks using concurrency.
  Its responsibilities include:
  - Reading directories and resolving file paths.
  - Coordinating parallel execution of file processing tasks.
  - Normalizing and validating parallel execution options.
  - Handling empty directories, empty file lists, and invalid options gracefully.

  It acts as the central orchestration layer for parallel processing,
  delegating actual file handling to the sequential processor while
  controlling concurrency, timeouts, and execution flow.
  """

  def process_directory(path) when is_bitstring(path) do
    cond do
      File.regular?(path) ->
        process_files([path])

      File.dir?(path) ->
        case File.ls(path) do
          {:ok, []} ->
            {:warning, "Directory is empty"}

          {:ok, files} ->
            files
            |> Enum.map(&Path.join(path, &1))
            |> process_files()

          {:error, reason} ->
            {:error, reason}
        end

      true ->
        {:error, "File not found"}
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
    case length(files) do
      0 ->
        {:error, "List of files is empty"}

      _ ->
        case Enum.all?(files, fn x -> File.regular?(x) end) do
          true ->
            totalFiles = length(files)

            task =
              files
              |> Enum.with_index(1)
              |> Enum.map(fn {path, index} ->
                Task.async(fn ->
                  result = FileProcessor.Sequential.process(path)
                  IO.puts("[#{index} / #{totalFiles}] Procesado")
                  result
                end)
              end)

            task
            |> Enum.map(fn task ->
              try do
                Task.await(task, 5_000)
              catch
                :exit, {:timeout, _} -> {:error, :timeout}
                :exit, reason -> {:error, reason}
              end
            end)

          false ->
            Enum.map(files, fn x -> process_directory(x) end)
        end
    end
  end

  def process_files(files, options) when is_list(files) do
    %{max_workers: max_workers, timeout: timeout} =
      normalize_options(options)

    total_files = length(files)

    files
    |> Enum.with_index(1)
    |> Task.async_stream(
      fn {path, index} ->
        result = FileProcessor.Sequential.process(path)
        IO.puts("[#{index} / #{total_files}] Procesado")
        result
      end,
      max_concurrency: max_workers,
      timeout: timeout
    )
    |> Enum.map(fn
      {:ok, res} ->
        res

      {:exit, :timeout} ->
        {:error, :timeout}

      {:exit, reason} ->
        {:error, reason}
    end)
  end

  defp normalize_options(options) do
    max_workers =
      case Map.get(options, :max_workers) do
        value when is_integer(value) and value > 0 ->
          value

        _ ->
          System.schedulers_online()
      end

    timeout =
      case Map.get(options, :timeout) do
        value when is_integer(value) and value > 0 ->
          value

        _ ->
          5_000
      end

    %{max_workers: max_workers, timeout: timeout}
  end
end
