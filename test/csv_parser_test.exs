defmodule FileProcessor.Parser.CSVTest do
  use ExUnit.Case

  test "process a valid CSV" do
    {:ok, result} =
      FileProcessor.Parser.CSV.parse("data/valid/ventas_enero.csv")

    assert result.state == :ok
    assert result.metrics != %{}
    assert result.metrics.total_sales > 0
  end

  test "process invalid CSV" do
    {:ok, result} =
      FileProcessor.Parser.CSV.parse("data/error/ventas_corrupto.csv")

    assert result.state in [:error, :partial]
    assert length(result.errors) > 0
  end
end
