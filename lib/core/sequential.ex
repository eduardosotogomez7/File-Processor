defmodule FileProcessor.Sequential do
  # Esta primera funcion nos indica el flujo de trabajo que va a tener cualquier path que nos llegue por parámetro
  # Aqui nos vamos a encargar de ver si el path no es una cadena vacía, verificar si existe
  # Obentener detalles como pueden ser la extension o si es directorio, lista de archivos o un solo path
  # y finalmente obtener el reporte
  # Cada uno de los pasos de esta funcion devuelve un valor el cual ayuda al sigiente paso del flujo tomar decisiones
  # Entonces tanto los resultados como los errores se van propagando
  def process(path) when is_bitstring(path) do
    case String.trim(path) do
      "" ->
        {:error, "Path can not be empty"}

      _ ->
        path
        |> fileExists?()
        |> obtainDetails()
        |> obtainReport()
    end
  end


  # Maneja el caso en el que se recibe una lista vacía.
  #
  # Se considera una advertencia ya que no hay archivos para procesar,
  # pero no representa un error de ejecución.
  def process([]) do
    {:warning, "No files to process"}
  end


  # Maneja el caso en el que se recibe una lista de paths.
  #
  # Primero valida que todos los elementos de la lista sean cadenas.
  # Si la validación es correcta, procesa cada path de forma individual
  # reutilizando la función process/1
  def process(files) when is_list(files) do
    case Enum.all?(files, &is_bitstring/1) do
      true ->
        Enum.map(files, &process/1)

      false ->
        {:error, "Invalid list. All elements must be file paths as strings."}
    end
  end


  # Cláusula de seguridad para cualquier tipo de entrada no válida.
  #
  # Evita fallos inesperados y proporciona un mensaje de error claro
  # cuando el tipo de dato recibido no es soportado.
  def process(_) do
    {:error, "Invalid input. Expected a file path as a string or a list of file paths."}
  end


  # Verifica la existencia de un archivo o directorio en el sistema.
  #
  # Recibe un path como cadena y utiliza File.exists?/1 para validar
  # si dicho path existe en el sistema de archivos.
  #
  # Retorna:
  # - {:ok, path} si el archivo o directorio existe.
  # - {:error, "File not found"} si el path no existe.
  #
  # Esta función es utilizada como primer filtro dentro del flujo
  # de procesamiento para evitar operaciones sobre paths inválidos.
  defp fileExists?(path) do
    case File.exists?(path) do
      true -> {:ok, path}
      false -> {:error, "File not found"}
    end
  end


  # Obtiene información básica del path validado previamente.
  #
  # Esta función recibe el resultado de fileExists?/1 y decide
  # cómo continuar el flujo según el tipo de path.
  #
  # Casos:
  # - Si recibe {:error, _}, propaga el error sin modificarlo.
  # - Si recibe {:ok, path}:
  #   - Retorna {:file, extension, path} si el path es un archivo regular.
  #   - Retorna {:dir, path} si el path es un directorio.
  #
  # Esta información es utilizada posteriormente para decidir
  # qué tipo de procesamiento se debe aplicar (archivo o directorio).
  defp obtainDetails({:error, _} = error) do
    error
  end

  defp obtainDetails({:ok, path}) do
    cond do
      File.regular?(path) -> {:file, Path.extname(path), path}
      File.dir?(path) -> {:dir, path}
    end
  end


  # Genera el reporte correspondiente según el tipo de recurso recibido.
  #
  # Esta función es responsable de:
  # - Delegar el procesamiento de archivos a su handler correspondiente
  #   según la extensión (.csv, .json, .log).
  # - Manejar directorios recorriendo su contenido de forma recursiva.
  # - Propagar errores cuando el flujo previo falla.
  #
  # Recibe como entrada una tupla generada por obtainDetails/1
  # y devuelve el resultado final del procesamiento.


  # Maneja el procesamiento de archivos CSV.
  # Llama al handler correspondiente y normaliza la respuesta
  # para mantener un formato de salida consistente.
  defp obtainReport({:file, ".csv", path}) do
    case FileProcessor.Handler.CSV.process(path) do
      {:ok, final_path} -> {:ok, :csv, final_path}
      {:partial, _} -> {:partial, :csv, path}
      {:error, _} -> {:error, :csv, path}
    end
  end

  # Maneja el procesamiento de archivos JSON.
  # Delegando el flujo al handler JSON y retornando el estado final.
  defp obtainReport({:file, ".json", path}) do
    case FileProcessor.Handler.JSON.process(path) do
      {:ok, final_path} -> {:ok, :json, final_path}
      {:partial, _} -> {:partial, :json, path}
      {:error, _} -> {:error, :json, path}
    end
  end

  # Maneja el procesamiento de archivos LOG.
  # Este tipo de archivo se procesa con métricas específicas
  # relacionadas con niveles y patrones de error.
  defp obtainReport({:file, ".log", path}) do
    case FileProcessor.Handler.LOG.process(path) do
      {:ok, final_path} -> {:ok, :log, final_path}
      {:partial, _} -> {:partial, :log, path}
      {:error, _} -> {:error, :log, path}
    end
  end

  defp obtainReport({:file, _, path}) do
    {:error, "Extension not allowed", path}
  end


  # Maneja el procesamiento de directorios.
  # Si el directorio está vacío se retorna una advertencia,
  # de lo contrario se inicia el procesamiento recursivo
  # de su contenido
  defp obtainReport({:dir, path}) do
    case File.ls(path) do
      {:ok, []} ->
        {:warning, "The directory is empty"}

      {:ok, _} ->
        process_directory(path)
    end
  end

  defp obtainReport({:error, _} = error) do
    error
  end

  defp process_directory(path) do
    case File.ls(path) do
      {:ok, []} ->
        {:warning, "The Directory is Empty"}

      {:ok, files} ->
        files
        |> Enum.map(fn x -> Path.join(path, x) end)
        |> Enum.map(fn file ->
          cond do
            File.regular?(file) ->
              process(file)

            File.dir?(file) ->
              process_directory(file)

            true ->
              {:error, "Unsoported file type: #{file}"}
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
