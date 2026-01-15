defmodule FileProcessor.Reporter do

  def buil_report(extension, filename, result) do

    header() <>
    section(extension, filename, result)
  end

  def save_report(extension, filename, report_content) do
    File.mkdir_p!("data/output")

    path = output_path(extension, filename)
    case File.write(path, report_content) do
      :ok -> {:ok, path}
      {:error, reason} -> {:error, reason}
    end



  end

  defp output_path(extension, filename) do
    base_name =
      filename
      |> Path.basename()
      |> Path.rootname()

    "data/output/reporter_#{extension}_#{base_name}.txt"
  end

  defp header() do
    """
    =================================================================
                      REPORTE DE PROCESAMIENTO DE ARCHIVOS
    =================================================================
    """
  end


  defp section(:csv, filename, result) do
    metrics = result.metrics

    """
    MÉTRICAS DE ARCHIVOS CSV
    ----------------------------------------------------------------
    [Archivo: #{Path.basename(filename)}]

    Estado del procesamiento: #{result.state}
    Líneas procesadas: #{result.processed_lines}
    Líneas válidas: #{result.valid_lines}
    Líneas con error: #{result.error_lines}

    #{csv_metrics(metrics)}

    #{csv_errors(result.errors)}
  """
  end


defp section(:json, filename, result) do
  metrics = result.metrics

  """
  MÉTRICAS DE ARCHIVOS JSON
  ----------------------------------------------------------------
  [Archivo: #{Path.basename(filename)}]

  Estado del procesamiento: #{result.state}

  #{json_metrics(metrics)}

  #{json_errors(result.errors)}
  """
end


  defp section(:log, filename, result) do
  metrics = result.metrics

  """
  MÉTRICAS DE ARCHIVOS LOG
  ----------------------------------------------------------------
  [Archivo: #{Path.basename(filename)}]

  Estado del procesamiento: #{result.state}

  #{log_metrics(metrics)}

  #{log_errors(result.errors)}
  """
end


defp log_metrics(metrics) when map_size(metrics) == 0 do
  """
  No fue posible calcular métricas porque no hubo líneas válidas.
  """
end

defp log_metrics(metrics) do
  levels_text =
    metrics.distribution_by_level
    |> Enum.map(fn {level, count} ->
      "    - #{level}: #{count}"
    end)
    |> Enum.join("\n")

  hours_text =
    metrics.distribution_by_hour
    |> Enum.map(fn {hour, count} ->
      "    - #{hour}:00 -> #{count} logs"
    end)
    |> Enum.join("\n")

  most_errors_text =
    case metrics.most_errors do
      nil ->
        "    No se detectaron errores."

      {component, count} ->
        "    #{component} (#{count} errores)"
    end

  frequent_errors_text =
    case metrics.frequent_errors do
      [] ->
        "    No se encontraron errores frecuentes."

      errors ->
        errors
        |> Enum.take(5)
        |> Enum.map(fn {message, count} ->
          "    - \"#{message}\" (#{count} veces)"
        end)
        |> Enum.join("\n")
    end

  critical_time_text =
    case metrics.time_between_critical_errors do
      [] ->
        "    No hay suficientes errores críticos para calcular intervalos."

      times ->
        times
        |> Enum.map(fn seconds ->
          "    - #{seconds} segundos"
        end)
        |> Enum.join("\n")
    end

  recurrent_patterns_text =
    case metrics.recurrent_error_patterns do
      [] ->
        "    No se detectaron patrones recurrentes."

      patterns ->
        patterns
        |> Enum.take(5)
        |> Enum.map(fn {word, count} ->
          "    - #{word} (#{count})"
        end)
        |> Enum.join("\n")
    end

  """
  MÉTRICAS CALCULADAS
  ----------------------------------------------------------------
    * Distribución por nivel:
  #{levels_text}

    * Componente con más errores:
  #{most_errors_text}

    * Distribución por hora:
  #{hours_text}

    * Errores más frecuentes:
  #{frequent_errors_text}

    * Tiempo entre errores críticos:
  #{critical_time_text}

    * Patrones de error recurrentes:
  #{recurrent_patterns_text}
  """
end



defp log_errors([]) do
  """
  No se encontraron errores en el archivo.
  """
end


defp log_errors(errors) do
  error_details =
    errors
    |> Enum.map(fn {line, reason} ->
      "  - Línea #{line}: #{reason}"
    end)
    |> Enum.join("\n")

  """
  ERRORES DETECTADOS
  ----------------------------------------------------------------
  #{error_details}
  """
end




defp json_metrics(metrics) when map_size(metrics) == 0 do
  """
  No fue posible calcular métricas porque no hubo datos válidos.
  """
end

defp json_metrics(metrics) do
  {hour, count} = metrics.peak_activity

  """
  MÉTRICAS CALCULADAS
  ----------------------------------------------------------------
  * Usuarios registrados: #{metrics.total_users}
  * Usuarios activos: #{metrics.active_vs_inactive_users.active}
  * Usuarios inactivos: #{metrics.active_vs_inactive_users.inactive}
  * Duración promedio de sesión: #{metrics.average_sessions} segundos
  * Total de páginas visitadas: #{metrics.total_pages_visited}
  * Top 5 acciones más comunes:
  #{format_top_actions(metrics.top_five_actions)}
  * Hora pico de actividad: #{hour}:00 (#{count} eventos)
  """
end


defp format_top_actions(actions) when is_list(actions) do
  actions
  |> Enum.with_index(1)
  |> Enum.map(fn {{action, count}, index} ->
    "    #{index}. #{action} (#{count})"
  end)
  |> Enum.join("\n")
end




defp json_errors([]) do
  """
  No se encontraron errores en el archivo.
  """
end

defp json_errors(errors) do
  error_details =
    Enum.map(errors, fn
      %Jason.DecodeError{position: pos} ->
        "  - Error de formato JSON cerca de la posición #{pos}"

      {:usuarios, index, reason} ->
        "  - Usuario ##{index}: #{reason}"

      {:sesiones, index, reason} ->
        "  - Sesión ##{index}: #{reason}"

      other ->
        "  - Error desconocido: #{inspect(other)}"
    end)
    |> Enum.join("\n")

  """
  ERRORES DETECTADOS
  ----------------------------------------------------------------
  #{error_details}
  """
end



  defp csv_metrics(metrics) when map_size(metrics) == 0 do
  """
  No fue posible calcular métricas porque no hubo líneas válidas.
  """
end

defp csv_metrics(metrics) do
  """
  MÉTRICAS CALCULADAS
  ----------------------------------------------------------------
  * Total de ventas: $#{Float.round(metrics.total_sales, 2)}
  * Productos únicos: #{metrics.unique_products}
  * Producto más vendido: #{elem(metrics.best_seller, 0)} (#{elem(metrics.best_seller, 1)} unidades)
  * Categoría con más ingresos: #{elem(metrics.best_category, 0)}
  * Promedio de descuento: #{metrics.average_amount}
  * Rango de fechas: Desde #{elem(metrics.date_range, 0)} Hasta #{elem(metrics.date_range, 1)}
  """
end

defp csv_errors([]) do
  """
  No se encontraron errores en el archivo.
  """
end

defp csv_errors(errors) do
  error_details =
    errors
    |> Enum.map(fn {line, reason} ->
      "  - Línea #{line}: #{reason}"
    end)
    |> Enum.join("\n")

  """
  ERRORES DETECTADOS
  ----------------------------------------------------------------
  #{error_details}
  """
end











end
