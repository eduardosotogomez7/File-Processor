defmodule FileProcessor.Parser.LOGTest do
  use ExUnit.Case

  alias FileProcessor.Parser.LOG

  describe "parse/1 valid cases" do
    test "returns :ok when all log lines are valid" do
      {:ok, result} = LOG.parse("data/valid/aplicacion.log")

      assert result.state == :ok
      assert result.errors == []

      assert is_map(result.metrics)
      assert Map.has_key?(result.metrics, :most_errors)
      assert Map.has_key?(result.metrics, :distribution_by_level)
      assert Map.has_key?(result.metrics, :distribution_by_hour)
      assert Map.has_key?(result.metrics, :frequent_errors)
      assert Map.has_key?(result.metrics, :time_between_critical_errors)
      assert Map.has_key?(result.metrics, :recurrent_error_patterns)
    end
  end

  describe "parse/1 partial success" do
    test "returns :partial when some log lines are invalid" do
      {:partial, result} = LOG.parse("data/error/aplicacion_partial.log")

      assert result.state == :partial
      assert result.errors != []

      assert is_list(result.errors)
      assert Enum.all?(result.errors, fn {line, reason} ->
        is_integer(line) and reason == :invalid_log_format
      end)


    end
  end

  describe "parse/1 error cases" do
    test "returns :error when no valid log entries are found" do
      {:error, result} = LOG.parse("data/error/invalid.log")

      assert result.state == :error
      assert result.errors != []
    end


  end

  describe "metrics structure contracts" do
    test "distribution_by_level is a map of level => count" do
      {:ok, result} = LOG.parse("data/valid/sistema.log")

      distribution = result.metrics.distribution_by_level

      assert is_map(distribution)

      Enum.each(distribution, fn {level, count} ->
        assert is_binary(level)
        assert is_integer(count)
      end)
    end

    test "time_between_critical_errors always returns a list" do
      {:ok, result} = LOG.parse("data/valid/sistema.log")

      assert is_list(result.metrics.time_between_critical_errors)
    end

    test "recurrent_error_patterns returns a sorted list of {word, count}" do
      {:ok, result} = LOG.parse("data/valid/sistema.log")

      patterns = result.metrics.recurrent_error_patterns

      assert is_list(patterns)

      Enum.each(patterns, fn {word, count} ->
        assert is_binary(word)
        assert is_integer(count)
      end)
    end
  end
end
