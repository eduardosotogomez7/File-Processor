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
