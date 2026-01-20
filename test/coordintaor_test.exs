defmodule FileProcessor.Parallel.CoordinatorTest do
  use ExUnit.Case, async: true

  alias FileProcessor.Parallel.Coordinator

  setup do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "fp_test_#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)

    log_file = Path.join(tmp_dir, "test.log")

    File.write!(
      log_file,
      "2024-01-01 10:00:00 [INFO] [Test] Hello world"
    )

    on_exit(fn ->
      File.rm_rf(tmp_dir)
    end)

    %{
      dir: tmp_dir,
      log_file: log_file
    }
  end

  # ---------------------------------------------------------
  # process_directory/1
  # ---------------------------------------------------------

  test "process_directory/1 returns warning for empty directory", %{dir: dir} do
    # Vaciar el directorio
    File.rm_rf!(dir)
    File.mkdir_p!(dir)

    assert {:warning, "Directory is empty"} =
             Coordinator.process_directory(dir)
  end

  test "process_directory/1 returns error for invalid path" do
    assert {:error, "File not found"} =
             Coordinator.process_directory("this/path/does/not/exist")
  end

  test "process_directory/1 processes single file", %{log_file: file} do
    result = Coordinator.process_directory(file)

    assert is_list(result)
    assert length(result) == 1
  end

  # ---------------------------------------------------------
  # process_directory/2
  # ---------------------------------------------------------

  test "process_directory/2 rejects non-map options", %{dir: dir} do
    assert {:error, "Options must be a map"} =
             Coordinator.process_directory(dir, "not_a_map")
  end

  # ---------------------------------------------------------
  # process_files/1
  # ---------------------------------------------------------

  test "process_files/1 returns error for empty list" do
    assert {:error, "List of files is empty"} =
             Coordinator.process_files([])
  end

  test "process_files/1 processes file list", %{log_file: file} do
    result = Coordinator.process_files([file])

    assert is_list(result)
    assert length(result) == 1
  end

  # ---------------------------------------------------------
  # process_files/2
  # ---------------------------------------------------------

  test "process_files/2 works with valid options", %{log_file: file} do
    options = %{
      max_workers: 2,
      timeout: 5_000
    }

    result = Coordinator.process_files([file], options)

    assert is_list(result)
    assert length(result) == 1
  end
end
