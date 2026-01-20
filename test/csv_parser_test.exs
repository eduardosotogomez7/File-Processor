defmodule FileProcessor.Parser.CSVTest do
  use ExUnit.Case

  alias FileProcessor.Parser.CSV

  describe "parse/1 with valid data" do
    test "processes a valid CSV file correctly" do
      {:ok, result} = CSV.parse("data/valid/ventas_enero.csv")

      assert result.state == :ok
      assert result.processed_lines > 0
      assert result.valid_lines == result.processed_lines
      assert result.error_lines == 0
      assert result.errors == []

      assert is_map(result.metrics)
      assert result.metrics.total_sales > 0
      assert result.metrics.unique_products > 0
      assert is_tuple(result.metrics.best_seller)
      assert is_tuple(result.metrics.best_category)
      assert is_float(result.metrics.average_amount)
      assert is_tuple(result.metrics.date_range)
    end
  end

  describe "parse/1 with partially invalid data" do
    test "returns :partial state when some rows are invalid" do
      {:partial, result} = CSV.parse("data/error/ventas_corrupto.csv")

      assert result.state == :partial
      assert result.errors > 0
    end
  end

  describe "parse/1 with invalid data" do
    test "returns :error state when all rows are invalid" do
      {:error, result} = CSV.parse("data/error/ventas_corrupto_copy.csv")

      assert result.state == :error
      assert result.errors > 0
    end
  end

  describe "parse/1 error handling" do
    test "returns error when file does not exist" do
      assert {:error, _reason} = CSV.parse("data/valid/no_existe.csv")
    end


  end
end
