defmodule FileProcessor.Handler.LOG do
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
