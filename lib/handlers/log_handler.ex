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
    {:ok, result} = FileProcessor.Parser.LOG.parse(path)

    FileProcessor.ErrorLogger.log_errors(
      %{extension: :log, filename: path},
      result.errors
    )

    report =
      FileProcessor.Reporter.buil_report(
        :log,
        path,
        result
      )

    FileProcessor.Reporter.save_report(:log, path, report)
  end
end
