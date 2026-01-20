defmodule FileProcessor.Parser.JSONTest do
  use ExUnit.Case

  alias FileProcessor.Parser.JSON

  describe "parse/1 with valid JSON data" do
    test "processes a valid JSON file correctly" do
      {:ok, result} = JSON.parse("data/valid/sesiones.json")

      assert result.state == :ok
      assert result.errors == []

      assert is_map(result.metrics)
      assert result.metrics.total_users > 0
      assert is_map(result.metrics.active_vs_inactive_users)
      assert result.metrics.average_sessions >= 0
      assert result.metrics.total_pages_visited >= 0
      assert is_list(result.metrics.top_five_actions)
      assert is_tuple(result.metrics.peak_activity) or is_nil(result.metrics.peak_activity)
    end
  end

  describe "parse/1 with partially invalid JSON data" do
    test "returns :partial when some users or sessions are invalid" do
      {:partial, result} = JSON.parse("data/error/usuarios_partial.json")

      assert result.state == :partial
      assert length(result.errors) > 0

    end
  end

  describe "parse/1 with invalid JSON data" do
    test "returns :error when all users and sessions are invalid" do
      {:error, result} = JSON.parse("data/error/usuarios_malformado.json")

      assert result.state == :error
      assert length(result.errors) > 0
    end
  end

  describe "parse/1 structure and decoding errors" do
    test "returns error state when JSON is malformed" do
      {:error, result} = JSON.parse("data/error/usuarios_malformado.json")

      assert result.state == :error
      assert length(result.errors) == 1
    end
  end


end
