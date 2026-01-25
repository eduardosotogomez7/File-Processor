defmodule FileProcessor.Handler.JSON do
  @moduledoc """
  Handler module responsible for processing JSON files.

  This module manages the complete JSON processing pipeline:
  - Parses the JSON file.
  - Logs parsing errors, if any.
  - Builds a report describing the processing result.
  - Saves the generated report to disk.

  It serves as an integration point between the JSON parser,
  error logging, and report generation components.
  """


  # Basicamente esta funcion es llamada desde el archivo sequential.ex o el coordinator.ex
  # Ayuda principalemte ya que accedemos a ella una vez que sabemos que nuestra ruta del archivo a procesar es
  # una ruta válida, es una ruta con extension json, entonces con esta funcion simplemente empezamos
  # el proceso que va a llevar un archivo json, el cual empieza con realizar el parse del archivo y en caso posible
  # obtener todas las metricas, esto se hace llamando a la funcion parse que se encuentra en
  # parsers/json.ex, esa funcion nos va a devolver un resultado y depende de cual sea vamos a mandar a llamar a la
  # generacion del reporte o a la generacion de un archivo con el log de errores
  def process(path) do
    case FileProcessor.Parser.JSON.parse(path) do
      {:ok, result} ->
        report = FileProcessor.Reporter.buil_report(:json, path, result)
        FileProcessor.Reporter.save_report(:json, path, report)

      {:partial, errors} ->
        FileProcessor.ErrorLogger.log_errors(
          %{extension: :json, filename: path},
          errors.errors, errors.state
        )

      {:error, errors} ->
        FileProcessor.ErrorLogger.log_errors(
          %{extension: :json, filename: path},
          errors.errors, errors.state
        )
    end
  end
end
