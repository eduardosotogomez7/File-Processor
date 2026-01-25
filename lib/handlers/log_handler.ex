defmodule FileProcessor.Handler.LOG do
  @moduledoc """
Handler module responsible for processing LOG files.

This module handles the processing flow for log files:
- Parses the log file content.
- Registers any detected errors.
- Generates a processing report.
- Stores the report for later inspection.

It centralizes the coordination of parsing, error logging,
and reporting specifically for LOG file processing.
"""


  # Basicamente esta funcion es llamada desde el archivo sequential.ex o el coordinator.ex
  # Ayuda principalemte ya que accedemos a ella una vez que sabemos que nuestra ruta del archivo a procesar es
  # una ruta válida, es una ruta con extension log, entonces con esta funcion simplemente empezamos
  # el proceso que va a llevar un archivo log, el cual empieza con realizar el parse del archivo y en caso posible
  # obtener todas las metricas, esto se hace llamando a la funcion parse que se encuentra en
  # parsers/log.ex, esa funcion nos va a devolver un resultado y depende de cual sea vamos a mandar a llamar a la
  # generacion del reporte o a la generacion de un archivo con el log de errores
  def process(path) do

    case FileProcessor.Parser.LOG.parse(path) do
      {:ok, result} ->
        report = FileProcessor.Reporter.buil_report(:log, path, result)
        FileProcessor.Reporter.save_report(:log, path, report)

      {:partial, errors} ->
        FileProcessor.ErrorLogger.log_errors(
          %{extension: :log, filename: path}, errors.errors, errors.state
        )

      {:error, errors} ->
        FileProcessor.ErrorLogger.log_errors(
          %{extension: :log, filename: path}, errors.errors, errors.state
        )
    end

  end
end
