defmodule FileProcessor.SequentialTest do
  use ExUnit.Case, async: true

  alias FileProcessor.Sequential

  setup do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "fp_seq_test_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)


    txt = Path.join(tmp_dir, "test.txt")


    File.write!(txt, "invalid")

    empty_dir = Path.join(tmp_dir, "empty")
    File.mkdir_p!(empty_dir)

    on_exit(fn ->
      File.rm_rf(tmp_dir)
    end)

    %{
      txt: txt,
      empty_dir: empty_dir,
      tmp_dir: tmp_dir
    }
  end

  # ---------------------------------------------------------
  # Invalid inputs
  # ---------------------------------------------------------

  test "process/1 returns error for empty path" do
    assert {:error, "Path can not be empty"} =
             Sequential.process("")
  end

  test "process/1 returns error for invalid input type" do
    assert {:error, _} =
             Sequential.process(123)
  end

  test "process/1 returns error for invalid list" do
    assert {:error, _} =
             Sequential.process(["ok", 123])
  end

  # ---------------------------------------------------------
  # File handling
  # ---------------------------------------------------------

  test "process/1 returns error when file does not exist" do
    assert {:error, "File not found"} =
             Sequential.process("no_such_file.txt")
  end

  test "process/1 processes csv file" do
    assert {:ok, :csv, _} =
             Sequential.process("data/valid/ventas_enero.csv")
  end

  test "process/1 processes json file" do
    assert {:ok, :json,_} =
             Sequential.process("data/valid/usuarios.json")
  end

  test "process/1 processes log file" do
    assert {:ok, :log,_} =
             Sequential.process("data/valid/sistema.log")
  end

  test "process/1 rejects unsupported extension", %{txt: txt} do
    assert {:error, "Extension not allowed", _} =
             Sequential.process(txt)
  end

  # ---------------------------------------------------------
  # Directory handling
  # ---------------------------------------------------------

  test "process/1 returns warning for empty directory", %{empty_dir: dir} do
    assert {:warning, "The directory is empty"} =
             Sequential.process(dir)
  end

  test "process/1 processes directory with files" do
  result = Sequential.process("data/valid")

  assert is_list(result)


end


  # ---------------------------------------------------------
  # List handling
  # ---------------------------------------------------------

  test "process/1 returns warning for empty list" do
    assert {:warning, "No files to process"} =
             Sequential.process([])
  end

  test "process/1 processes list of files"do
    result = Sequential.process(["data/valid/ventas_enero.csv", "data/valid/usuarios.json"])

    assert is_list(result)
    assert length(result) == 2
  end
end
