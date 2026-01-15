defmodule FileProcessor.Handler.JSON do
  def process(path) do
    {:ok, result} = FileProcessor.Parser.JSON.parse(path)

    FileProcessor.ErrorLogger.log_errors(
      %{extension: :json, filename: path},
      result.errors
    )

    report =
      FileProcessor.Reporter.buil_report(
        :json,
        path,
        result
      )

    FileProcessor.Reporter.save_report(:json, path, report)
  end
end
