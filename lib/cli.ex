defmodule FileProcessor.CLI do
  @moduledoc """
  Command line interface for the `FileProcessor` module.

  Allows executing any of the main processing functions directly from the terminal:

      file_processor process_secuential <path>
      file_processor process_parallel <path>
      file_processor benchmark <path>

  You can also call this with --help to see usage.
  """

  def main(args) do
    case args do
      ["--help"] ->
        print_help()

      [command, path] ->
        run_command(command, path, %{})

      [command, path | extra] ->
        # If there are options after path, parse them as key=value
        options = parse_options(extra)
        run_command(command, path, options)

      _ ->
        IO.puts("Invalid arguments. Use --help for usage instructions.")
    end
  end

  defp run_command("process_secuential", path, _opts) do
    result = FileProcessor.process_secuential(path)
    IO.puts(result)
  end

  defp run_command("process_parallel", path, opts) when map_size(opts) == 0 do
    result = FileProcessor.process_parallel(path)
    IO.puts(result)
  end

  defp run_command("process_parallel", path, opts) do
    result = FileProcessor.process_parallel(path, opts)
    IO.puts(result)
  end

  defp run_command("benchmark", path, _opts) do
    FileProcessor.benchmark(path)
  end

  defp run_command(cmd, _path, _opts) do
    IO.puts("Unknown command: #{cmd}. Use --help for usage.")
  end

  defp print_help do
    IO.puts("""
    FileProcessor CLI

    Usage:
      file_processor process_secuential <path>
        - Processes a single file or directory sequentially.

      file_processor process_parallel <path> [key=value ...]
        - Processes files in parallel. Optional key=value options:
            max_workers=<number>
            timeout=<milliseconds>

      file_processor benchmark <path>
        - Compares sequential vs parallel processing times.

      file_processor --help
        - Shows this help message.
    """)
  end

  defp parse_options(args) do
    Enum.reduce(args, %{}, fn arg, acc ->
      case String.split(arg, "=", parts: 2) do
        [key, value] ->
          Map.put(acc, String.to_atom(key), parse_value(value))

        _ ->
          acc
      end
    end)
  end

  defp parse_value(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end
end
