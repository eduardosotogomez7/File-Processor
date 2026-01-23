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
    args =
      Enum.map(args, fn x ->
        String.replace(x, ",", "")
      end)

    case args do
      ["--help"] ->
        print_help()

      [command | rest] ->
        {paths, option_args} = split_paths_and_options(rest)
        options = parse_options(option_args)
        run_command(command, paths, options)

      _ ->
        IO.puts(
          "Los argumentos fueron inválidos. Usa el comando --help para ver las instrucciones."
        )
    end
  end

  defp run_command("process_secuential", path, _opts) do
    case path do
      [] ->
        IO.puts("Se debe de ingresar al menos un archivo a procesar de manera secuencial")

      _ ->
        result = FileProcessor.process_secuential(path)
        Enum.map(result, fn x -> IO.puts(print_result(x)) end)
    end
  end

  defp run_command("process_parallel", path, opts) when map_size(opts) == 0 do
    Application.put_env(:file_processor, :show_progress, true)
    result = FileProcessor.process_parallel(path)

    Enum.each(result, fn x -> IO.puts(print_result(x)) end)
  after
    Application.put_env(:file_processor, :show_progress, false)
  end

  defp run_command("process_parallel", path, opts) do
    Application.put_env(:file_processor, :show_progress, true)

    {valid_opts, invalid_opts} = validate_options(opts)

    if invalid_opts != [] do
      invalid_keys =
        invalid_opts
        |> Enum.map(fn {k, _} -> k end)
        |> Enum.join(", ")

      IO.puts("""
      Advertencia:
      Las siguientes opciones son inválidas y se usarán los valores por defecto:
        #{invalid_keys}
      """)
    end

    try do
      result =
        case map_size(valid_opts) do
          0 ->
            FileProcessor.process_parallel(path)

          _ ->
            FileProcessor.process_parallel(path, valid_opts)
        end

      Enum.map(result, fn x -> IO.puts(print_result(x)) end)
    catch
      :exit, {:timeout, _} ->
        IO.puts("""
        Procesamiento cancelado por tiempo de espera.

        El tiempo configurado fue insuficiente para completar el procesamiento.
        Sugerencia:
          - Aumenta el valor de timeout (ej. timeout=5000)
          - Reduce el número de archivos
        """)
    after
      Application.put_env(:file_processor, :show_progress, false)
    end
  end

  defp run_command("benchmark", path, _opts) do
    resultado = FileProcessor.benchmark(path)
    IO.inspect(resultado)
  end

  defp run_command(cmd, _path, _opts) do
    IO.puts("Comando desconocido: #{cmd}. Usa --help para ver la guia de uso.")
  end

  defp print_help do
    IO.puts("""
    FileProcessor

    Guía de uso:

      Para procesamiento de un archivo o un directorio de manera secuencial se debe de usar la siguiente estructura

      file_processor process_secuential <path>

          Ejemplos:

          ./file_processor process_secuential data/valid/ventas_enero.csv
          ./file_processor process_secuential data/valid

          Se recomienda poner entre comillas las rutas de archivos y directorios, especialmente
          si estas tienen espacios


      Para procesamiento de una lista de archivos de manera secuencial, las rutas deben separarse usando espacios

          Ejemplo:

          ./file_processor process_secuential data/valid/ventas_enero.csv data/valid/ventas_febrero.csv



      Para procesamiento de un archivo o directorio de manera parallela se debe de seguir la siguiente estructura

      file_processor process_parallel <path>

          Ejemplos:

          ./file_processor process_parallel data/valid/ventas_enero.csv
          ./file_processor process_parallel data/valid

      Para procesamiento de una lista de archivos de manera parallela, las rutas deben separarse usanndo espacios

          Ejemplo:

          ./file_processor process_parallel data/valid/ventas_enero.csv data/valid/ventas_febrero.csv


      Para el procesamiento de manera parallela utilizando opciones (max_workers, timeout) se debe de
      usar la siguient estructura


      file_processor process_parallel <path> [key=value ...]
          max_workers=<numero>
          timeout=<millisegundos>

          Ejemplo ./fileprocessor process_parallel data/valid max_workers=2 timeout=5000

      Para comparar el tiempo de procesamiento entre secuencial y parallelo se puede usar la siguiente
      instrucción



      file_processor benchmark <path>

          Ejemplo:

          ./file_processor benchmark data/valid


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

  defp split_paths_and_options(args) do
    Enum.split_with(args, fn arg ->
      not String.contains?(arg, "=")
    end)
  end

  defp validate_options(opts) do
    {valid, invalid} =
      Enum.split_with(opts, fn
        {:max_workers, v} when is_integer(v) and v > 0 -> true
        {:timeout, v} when is_integer(v) and v >= 0 -> true
        _ -> false
      end)

    {Map.new(valid), invalid}
  end

  defp print_result(result) do
    case result do
      {:ok, _, final_path} ->
        """
        Reporte generado correctamente.
        Reporte guardado en #{final_path}
        """

      {:partial, _, final_path} ->
        """
        El archivo #{Path.basename(final_path)} tiene lineas no válidas para la generacíon del reporte, procesar este archivo
        tendrá resultados incorrectos o inconsistente, para revisar los errores ve a la siguiente ruta
        data/output/errors.log
        """

      {:error, "Extension not allowed", path} ->
        """
        La extension del archivo #{Path.basename(path)} no es permitida, solamente se pueden procesar archivos con extension
        csv,json,log
        """

      {:error, _, final_path} ->
        """
        El archivo #{Path.basename(final_path)} no contiene lineas validas para poder generar el reporte, para revisar los errores
        ve a las siguiente ruta data/output/errors.log
        """

      {:error, "File not found"} ->
        """
        El archivo ingresado no fue encontrado, asegurate que exista.

        Recuerda consultar la guia con el comando --help
        """

      {:warning, "The directory is empty"} ->
        """
        El directorio ingresado esta vacío, no se proceso nungún archivo
        """

      list when is_list(list) ->
        Enum.each(list, fn x -> IO.puts(print_result(x)) end)
    end
  end
end
