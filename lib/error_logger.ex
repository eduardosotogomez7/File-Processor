defmodule FileProcessor.ErrorLogger do
  @error_log_path "data/output/errors.log"

  def log_errors(_context, []), do: :ok

  def log_errors(context, errors) when is_list(errors) do
    File.mkdir_p!("data/output")

    log_entry =
      build_log_entry(context, errors)

    File.write(@error_log_path, log_entry, [:append])
  end

  defp build_log_entry(context, errors) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    header = """
    [#{timestamp}]
    Archivo: #{context.filename}
    Tipo: #{context.extension}
    """

    errors_text =
      errors
      |> Enum.map(&format_error/1)
      |> Enum.join("\n")

    header <> errors_text <> "\n\n"
  end

  defp format_error(error) do
    "  - #{inspect(error)}"
  end
end
