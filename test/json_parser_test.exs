defmodule FileProcessor.Parser.JSONTest do
  use ExUnit.Case

  test "process a valid JSON" do
    {:ok, result} =
      FileProcessor.Parser.JSON.parse("data/valid/usuarios.json")

    assert result.state == :ok
    assert result.metrics.total_users > 0
  end

  test "process invalid JSON" do
    {:ok, result} =
      FileProcessor.Parser.JSON.parse("data/error/usuarios_malformado.json")

    assert result.state in [:error, :partial]
    assert length(result.errors) > 0
  end
end
