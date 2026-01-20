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
