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
