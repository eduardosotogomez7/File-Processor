defmodule FileProcessor.Parser.LOG do
  def parse(path) do

    {valid_logs, errors} =
      File.stream!(path)
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {line, index}, {valid, errors} ->
        case parse_line(line) do
          {:ok, log} ->
            {[log | valid], errors}

          {:error, reason} ->
            {valid, [{index + 1, reason} | errors]}
        end
      end)

    logs = Enum.reverse(valid_logs)
    errors = Enum.reverse(errors)

    metrics =
      case logs do
        [] -> %{}

        _ ->
          %{
            most_errors: component_with_most_errors(logs),
            distribution_by_level: distribution_by_level(logs),
            distribution_by_hour: distribution_by_hour(logs),
            frequent_errors: most_frequent_errors(logs),
            time_between_critical_errors: time_between_critical_errors(logs),
            recurrent_error_patterns: recurrent_error_patterns(logs)
          }
      end



      state =
        cond do
          errors == [] -> :ok
          logs != [] -> :partial
          true -> :error
        end


      {:ok, %{state: state,
              metrics: metrics,
              errors: errors
      }}




  end

  defp parse_line(line) do
  line = String.trim(line)

  case String.split(line, " ", parts: 5) do
    [date, time, level, component, message] ->
      {:ok,
       %{
         date: date,
         time: time,
         level: clean(level),
         component: clean(component),
         message: message
       }}

    _ ->
      {:error, :invalid_log_format}
  end
end


  defp clean(value) do
    value
    |> String.trim_leading("[")
    |> String.trim_trailing("]")
  end

  #--------------------------------------------------------------------------
  #      Component with most errors
  #-------------------------------------------------------------------------



  defp component_with_most_errors(logs) do
    logs
    |> errors_by_component()
    |> Enum.max_by(fn {_component, count} -> count end, fn -> nil end)
  end

  defp errors_by_component(logs) do
    logs
    |> error_logs()
    |> Enum.group_by(& &1.component)
    |> Enum.map(fn {component,entries} -> {component, length(entries)} end)

  end

  defp error_logs(logs) do
    Enum.filter(logs, fn log -> log.level in ["ERROR", "FATAL"] end)
  end

  #-------------------------------------------------------------------------
  # Distribution by levels
  #--------------------------------------------------------------------------


  defp distribution_by_level(logs) do
    logs
    |> Enum.group_by(& &1.level)
    |> Enum.map(fn {level, entries} -> {level, length(entries)} end)
    |> Map.new()
  end

  #--------------------------------------------------------------
  # Distribution by hour
  #-------------------------------------------------------------
  defp distribution_by_hour(logs) do
    logs
    |> Enum.group_by(fn log -> hour_of_log(log.time) end)
    |> Enum.map(fn {hour, entries} -> {hour, length(entries)} end)
  end

  defp hour_of_log(time) do
    time
    |> String.split(":")
    |> List.first()
  end

#--------------------------------------------------------------------------
#   Most frequent error messages
#--------------------------------------------------------------------------

defp most_frequent_errors(logs) do
  logs
  |> error_logs()
  |> Enum.group_by(& &1.message)
  |> Enum.map(fn {message, entries} -> {message, length(entries)} end)
  |> Enum.sort_by(fn {_msg, count} -> count end, :desc)
end


#--------------------------------------------------------------------------
#   Time between critical errors (seconds)
#--------------------------------------------------------------------------

defp time_between_critical_errors(logs) do
  logs
  |> critical_errors()
  |> Enum.map(&to_naive_datetime/1)
  |> Enum.sort()
  |> calculate_time_differences()
end

defp calculate_time_differences([]), do: []
defp calculate_time_differences([_]), do: []

defp calculate_time_differences(datetimes) do
  datetimes
  |> Enum.chunk_every(2, 1, :discard)
  |> Enum.map(fn [t1, t2] ->
    NaiveDateTime.diff(t2, t1, :second)
  end)
end


defp to_naive_datetime(log) do
  NaiveDateTime.from_iso8601!("#{log.date} #{log.time}")
end


defp critical_errors(logs) do
  Enum.filter(logs, fn log -> log.level == "FATAL" end)
end


#--------------------------------------------------------------------------
#   Recurrent error patterns
#--------------------------------------------------------------------------

defp recurrent_error_patterns(logs) do
  logs
  |> error_logs()
  |> Enum.flat_map(fn log -> extract_keywords(log.message) end)
  |> Enum.frequencies()
  |> Enum.sort_by(fn {_word, count} -> count end, :desc)
end


defp extract_keywords(message) do
  message
  |> String.downcase()
  |> String.replace(~r/[^a-z\s]/, "")
  |> String.split()
  |> Enum.reject(&(&1 in ["the", "and", "to", "of", "a", "in"]))
end







end
