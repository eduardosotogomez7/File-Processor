defmodule FileProcessor.Parser.JSON do
  def parse(path) do
  with {:ok, content} <- File.read(path),
       {:ok, data} <- Jason.decode(content),
       {:ok, validated} <- validate_structure(data),
       {:ok, metrics} <- calculate_metrics(validated) do

    state =
      cond do
        validated.errors == [] -> :ok
        validated.valid_usuarios != [] or validated.valid_sesiones != [] -> :partial
        true -> :error
      end

    {:ok, %{state: state, metrics: metrics, errors: validated.errors}}
  else
    {:error, reason} ->
      {:ok, %{state: :error, metrics: %{}, errors: [reason]}}
  end
end




  #-----------------------------------------------------------------------
  # Validate Structure
  #---------------------------------------------------------------------------

  def validate_structure(%{
      "timestamp" => timestamp,
      "usuarios" => usuarios,
      "sesiones" => sesiones
    })
    when is_bitstring(timestamp) and is_list(usuarios) and is_list(sesiones) do

  with {:ok, _} <- validate_timestamp(timestamp),
       {valid_users, user_errors} <- validate_usuarios(usuarios),
       {valid_sessions, session_errors} <- validate_sesiones(sesiones) do
    {:ok,
     %{
       timestamp: timestamp,
       valid_usuarios: valid_users,
       valid_sesiones: valid_sessions,
       errors: user_errors ++ session_errors
     }}
  end
end


defp validate_timestamp(timestamp) do
  case DateTime.from_iso8601(timestamp) do
    {:ok, _, _} -> {:ok, timestamp}
    {:error, _} -> {:error, :invalid_timestamp}
  end
end

defp validate_usuarios([]), do: {:error, :usuarios_empty}

defp validate_usuarios(usuarios) do
  usuarios
  |> Enum.with_index()
  |> Enum.reduce({[], []}, fn {user, index}, {valid, errors} ->
    case validate_usuario(user) do
      :ok -> {[user | valid], errors}
      {:error, reason} -> {valid, [{:usuarios, index + 1, reason} | errors]}
    end
  end)
  |> then(fn {v, e} -> {Enum.reverse(v), Enum.reverse(e)} end)
end

defp validate_usuario(%{
       "id" => id,
       "nombre" => nombre,
       "email" => email,
       "activo" => activo,
       "ultimo_acceso" => ultimo_acceso
     })
     when is_integer(id) and
          is_bitstring(nombre) and
          is_bitstring(email) and
          is_boolean(activo) and
          is_bitstring(ultimo_acceso) do
  case DateTime.from_iso8601(ultimo_acceso) do
    {:ok, _, _} -> :ok
    {:error, _} -> {:error, :invalid_ultimo_acceso}
  end
end

defp validate_usuario(_), do: {:error, :invalid_usuario}


defp validate_sesiones([]), do: {:error, :sesiones_empty}

defp validate_sesiones(sesiones) do
  sesiones
  |> Enum.with_index()
  |> Enum.reduce({[], []}, fn {session, index}, {valid, errors} ->
    case validate_sesion(session) do
      :ok -> {[session | valid], errors}
      {:error, reason} -> {valid, [{:sesiones, index + 1, reason} | errors]}
    end
  end)
  |> then(fn {v, e} -> {Enum.reverse(v), Enum.reverse(e)} end)
end

defp validate_sesion(%{
       "usuario_id" => usuario_id,
       "inicio" => inicio,
       "duracion_segundos" => duracion,
       "paginas_visitadas" => paginas,
       "acciones" => acciones
     })
     when is_integer(usuario_id) and
          is_bitstring(inicio) and
          is_integer(duracion) and duracion >= 0 and
          is_integer(paginas) and paginas >= 0 and
          is_list(acciones) do
  case DateTime.from_iso8601(inicio) do
    {:ok, _, _} -> :ok
    {:error, _} -> {:error, :invalid_inicio}
  end
end

defp validate_sesion(_), do: {:error, :invalid_sesion}



defp calculate_metrics(%{
  valid_usuarios: users,
  valid_sesiones: sessions
}) do
  {:ok,
   %{
     total_users: total_users(users),
     active_vs_inactive_users: active_vs_inactive_users(users),
     average_sessions: average_session(sessions),
     total_pages_visited: total_pages_visited(sessions),
     top_five_actions: top_actions(sessions),
     peak_activity: peak_activity_hour(sessions)
   }}
end






#---------------------------------------------------------------------------------
#  Total Users
#---------------------------------------------------------------------------------
  defp total_users(users) when is_list(users)  do
    length(users)
  end

#------------------------------------------------------------------------------
#     Active vs Inactive
#------------------------------------------------------------------------------
  defp active_vs_inactive_users(users) when is_list(users) do
    users
    |> Enum.reduce(%{active: 0, inactive: 0}, fn user, acc ->
      case user do
        %{"activo" => true} -> %{acc | active: acc.active + 1}
        %{"activo" => false} -> %{acc | inactive: acc.inactive + 1}
      end
    end)
  end

#---------------------------------------------------------------------------------
#    Average Session
#-------------------------------------------------------------------------------

  defp average_session(sessions) when is_list(sessions) do
    total_sessions = Enum.reduce(sessions,0, fn session, acc -> acc + time_session(session) end)

    total_sessions / length(sessions)
  end

  defp time_session(%{"duracion_segundos" => duration}) when is_integer(duration) do
    duration
  end


#---------------------------------------------------------------------------------
#  Total Pages Visited
#---------------------------------------------------------------------------------
defp total_pages_visited(sessions) when is_list(sessions) do
  Enum.reduce(sessions, 0, fn session, acc ->
    acc + pages_visited(session)
  end)
end

defp pages_visited(%{"paginas_visitadas" => pages}) when is_integer(pages) do
  pages
end


#---------------------------------------------------------------------------------
#  Top 5 Actions
#---------------------------------------------------------------------------------
defp top_actions(sessions) when is_list(sessions) do
  sessions
  |> Enum.flat_map(&actions_from_session/1)
  |> Enum.frequencies()
  |> Enum.sort_by(fn {_action, count} -> count end, :desc)
  |> Enum.take(5)
end

defp actions_from_session(%{"acciones" => actions}) when is_list(actions) do
  actions
end


#---------------------------------------------------------------------------------
#  Peak Activity Hour
#---------------------------------------------------------------------------------
defp peak_activity_hour(sessions) when is_list(sessions) do
  sessions
  |> Enum.map(&hour_from_session/1)
  |> Enum.frequencies()
  |> Enum.max_by(fn {_hour, count} -> count end, fn -> nil end)
end

defp hour_from_session(%{"inicio" => inicio}) when is_bitstring(inicio) do
  {:ok, datetime, _} = DateTime.from_iso8601(inicio)
  datetime.hour
end







end
