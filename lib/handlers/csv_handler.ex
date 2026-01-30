defmodule FileProcessor.Handler.CSV do
  @moduledoc """
  Handler module responsible for processing CSV files.

  This module coordinates the full CSV processing workflow:
  - Parses the CSV file.
  - Logs any errors found during parsing.
  - Builds a processing report based on the parsed result.
  - Persists the generated report to disk.

  It acts as an orchestration layer between the parser, error logger,
  and reporter components for CSV files.
  """

  # Comentario agregado 30/01/2026

  # Basicamente esta funcion es llamada desde el archivo sequential.ex o el coordinator.ex
  # Ayuda principalemte ya que accedemos a ella una vez que sabemos que nuestra ruta del archivo a procesar es
  # una ruta válida, es una ruta con extension csv, entonces con esta funcion simplemente empezamos
  # el proceso que va a llevar un archivo csv, el cual empieza con realizar el parse del archivo y en caso posible
  # obtener todas las metricas, esto se hace llamando a la funcion parse que se encuentra en
  # parsers/csv.ex, esa funcion nos va a devolver un resultado y depende de cual sea vamos a mandar a llamar a la
  # generacion del reporte o a la generacion de un archivo con el log de errores
  def process(path) do
    case FileProcessor.Parser.CSV.parse(path) do
      {:ok, result} ->
        report = FileProcessor.Reporter.buil_report(:csv, path, result)
        FileProcessor.Reporter.save_report(:csv, path, report)

      {:partial, errors} ->
        FileProcessor.ErrorLogger.log_errors(
          %{extension: :csv, filename: path},
          errors.errors, errors.state
        )

      {:error, errors} ->
        FileProcessor.ErrorLogger.log_errors(
          %{extension: :csv, filename: path},
          errors.errors, errors.state
        )


    end
  end
end
