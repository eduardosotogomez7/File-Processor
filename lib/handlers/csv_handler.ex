defmodule FileProcessor.Handler.CSV do
  def process(path) do
    {:ok, result} = FileProcessor.Parser.CSV.parse(path)

    FileProcessor.ErrorLogger.log_errors(
      %{extension: :csv, filename: path},
      result.errors
    )

    report =
      FileProcessor.Reporter.buil_report(
        :csv,
        path,
        result
      )

    FileProcessor.Reporter.save_report(:csv, path, report)
  end
end
