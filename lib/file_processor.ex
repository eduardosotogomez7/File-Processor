defmodule FileProcessor do
  @moduledoc """
  `FileProcessor` is the main entry point for processing files sequentially or in parallel.

  It provides functions to process a single file, multiple files, or entire directories.
  It also includes a benchmarking function to compare sequential and parallel processing times.

  More information

  h(FileProcessor.process_secuential)
  h(FileProcessor.process_parallel)
  h(FileProcessor.bencmark)
  """

  @doc """
  Processes a single file or a list of files sequentially.

  ## Parameters
    - path: A string representing the file, dir, or list files paths to be processed.

  ## Returns
    - The result of `FileProcessor.Sequential.process/1`, typically a map containing
      metrics, state, and errors of the processed file.
  """
  def process_secuential(path) do
    FileProcessor.Sequential.process(path)
  end


  @doc """
  Processes all files in a directory or a list of files in parallel using the default options.

  ## Parameters
    - path: A string representing the directory path containing files to process.

  ## Returns
    - A report of results for each processed file.
  """
  def process_parallel(path) when is_bitstring(path) do
    FileProcessor.Parallel.Coordinator.process_directory(path)
  end



  def process_parallel(files) when is_list(files) do
    FileProcessor.Parallel.Coordinator.process_files(files)
  end


  @doc """
  Processes all files in a directory in parallel using custom options.

  ## Parameters
    - path: A string representing the directory path containing files to process.
    - options: A map containing options for parallel processing, e.g.:
        - `:max_workers` - maximum number of concurrent tasks
        - `:timeout` - maximum time (ms) allowed for each task

  ## Returns
    - A list of results for each processed file, using the specified options.
  """
  def process_parallel(path, options) when is_bitstring(path) and is_map(options) do
  FileProcessor.Parallel.Coordinator.process_directory(path, options)
end

@doc """
  Benchmarks the processing of files in a given path, comparing sequential vs parallel execution.

  ## Parameters
    - path: A string representing the file or directory path to benchmark.

  ## Prints
    - Sequential execution time in microseconds.
    - Parallel execution time in microseconds.

  ## Example
      iex> FileProcessor.benchmark("data/")
      Secuential time : 15000
      Parallel Time: 5000
  """
def benchmark(path) do
  {secuential_time, _} = :timer.tc(fn -> process_secuential(path) end)

  {parallel_time, _} = :timer.tc(fn -> process_parallel(path) end)

  IO.puts("""

    Secuential time : #{secuential_time}
    Parallel Time: #{parallel_time}

  """)
end
end
