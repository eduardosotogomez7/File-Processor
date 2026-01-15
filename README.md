# File Processor - PRocesamiento de Archivos en Elixir

# Descripción

En este proyecto se implementa un sistema de procesamiento de archivos en elixir el cual es capaz de analizar 
archivos con extensión .csv, .json y .log, de los cuales se extraen métricas relevantes de cada uno de ellos y generar reportes correspondientes en texto plano

Este sistema se puede utilizar tanto para procesamiento secuencial como paralelo lo cual nos permite comparar el rendimiento entre uno y otro 

Además, el proyecto incluye un ejecutable, por lo que ya no es necesario abrir iex para ejecutar las funciones.

# Ejecución

## Usando IEx (Opcional)

Este proyecto se puede ejecutar directamente desde iex accediendo a la carpeta del proyecto y ejecutando el comando

iex -S mix

Ejemplo:
~/file_processor$ iex -S mix

## Usando el ejecutable (Recomendado)

Además el proyecto puede ser ejecutado directamente desde la consola de comandos con la siguiente estructura

./file_processor <function> <arguments>

<function>: es la función la cual se quiere llamar del módulo FileProcessor (process_secuential, process_parallel, benchmark) 

<argumentos>: Ruta al archivo, lista de archivos o directorio a procesar. Usa comillas si hay espacios en las rutas.


# Uso

## Uso con el comando iex -S mix

Una vez iniciado el proyecto con el comando (iex -S mix) se puede hacer uso del modulo "FileProcessor" para procesar uno o varios archivos o un directorio completo 

  ### Procesamiento Secuencial
  
  Para poder procesar uno o varios archivos o un directorio de manera secuencial se podrá hacer usa de la función "process_secuential/1" de la siguiente manera:

    Para procesar un solo archivo:
    FileProcessor.process_secuential("data/valid/ventas_enero.csv")

    Para procesar varios archivos:
    archivos = ["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]
    FileProcessor.process_secuential(archivos)

    Para procesar un directorio completo:
    FileProcessor.process_secuential("data/valid")
  
  El procesamiento secuencial procesa y analiza los archivos uno por uno

  ### Procesamiento Paralelo

  Para poder procesar varios archivos o un directorio completo de manera paralela se podrá hacer uso de la funcion "FileProcessor.process_parallel/1" de la siguiente manera:

    Para procesar varios archivos:
    archivos = ["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]
    FileProcessor.process_parallel(archivos)

    Para procesar un directorio completo:
    FileProcessor.process_parallel("data/valid")

  El procesamiento paralelo crea múltiples procesos haciendo uso de Task.async/1 lo cual nos permite que varios archivos se ejecuten de manera concurrente

  Durante el procesamiento paralelo se muestra un indicador de progreso indicando cuantos archivos han sido procesados

Cada archivo procesado ya sea de manera secuencial o paralela devuelve un resultado (tupla) con la siguiente estructura:

{:ok, :extension_del_archivo procesado} : En caso que se haya procesado correctamente

{:error, reason} : En caso que no se haya podido procesar el archivo o directorio

Para el caso del procesamiento paralelo, los resultados se recolectan una vez que todos los procesos han terminado su ejecución

## Uso con el ejecutable

### Procesamiento secuencial

Procesamiento secuencial de un solo archivo:
./file_processor process_secuential "data/valid/ventas_enero.csv"

Procesamiento secuencial de varios archivos:
./file_processor process_secuential '["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]'

Procesamiento secuencial de un directorio completo:
./file_processor process_secuential "data/valid"

### Procesamiento Paralelo

Procesamiento paralelo de varios archivos:
./file_processor process_parallel '["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]'

Procesamiento paralelo de un directorio completo:
./file_processor process_parallel "data/valid"

### Benchmark

Benchmark: comparación de tiempos secuencial vs paralelo:
./file_processor benchmark "data/valid"


Todas las rutas son relativas a la ubicación del ejecutable.




# Explicacion de deciciones de diseño

  ## Estructura del proyecto

  El proyecto decidí construirlo de manera modular, esto por constumbre a como hacía en proyectos de Java con el objetivo de separar bien las responsabilidades de cada uno de los modulos y de cada una de las carpetas que existen en el proyecto, lo cual me permite trabajr de una manera más rápida y a mi considreación más limpia 

  La estructura actual del proyecto es la siguiente:

  lib/
  ├── cli.ex 
  ├── file_processor.ex        
  ├── reporter.ex              
  ├── sequential.ex            
  ├── handlers/                
  │   ├── csv_handler.ex
  │   ├── json_handler.ex
  │   └── log_handler.ex
  ├── parsers/                  
  │   ├── csv.ex
  │   ├── json.ex
  │   └── log.ex
  └── parallel/
      ├── coordinator.ex       

  
  Con esta estructura lo que se hizo fué separar la lógica de todo lo que conlleva el procesamiento de archivos haciendo que cada modulo y cada carpeta tenga una responsabilidad clara 

  ### cli.ex

  El módulo FileProcessor.CLI convierte el proyecto en un ejecutable que puede ser usado desde la terminal.
  Su función principal es recibir argumentos desde la línea de comandos, interpretar qué función del módulo FileProcessor se debe ejecutar y con qué parámetros, y luego llamar a esa función.

  Esto permite que ya no sea necesario abrir IEx para procesar archivos; basta con escribir el comando desde la terminal.

  ### file_processor.ex

  Este módulo esta pensado para ser la API pública donde se encuentran las funciones que el usuario va a utilizar directamente para procesar archivos ya sea de manera secuencia o de manera paralela,  ayuda principalmente a que el usuario no conozca los detalles de como funciona cada procedimiento y de esta manera haya una interfaz clara para el usuario

  ### reporter.ex

  Este módulo se encarga de construir los reportes de los archivos una vez que eestos están procesados, esto me permite que este módulo simplemente se encarge de recibir las métricas obtenidas de los archivos procesados y se construya el reporte a partir de ellas sin que se tenga conocimiento de como se obtuvieron esas métricas o de todo lo que se tuvo que hacer para obtenerlas, simplemente las utiliza para construir un reporte

  ### secuential.ex
  

  Este módulo sirve como un coordinador del procesamiento secuencial de archivos y
  directorios.

  Su función principal es recibir una ruta como entrada y ejecutar una serie de
  pasos (usando operador pipe) encadenados que permiten validar la existencia de la ruta, identificar si
  corresponde a un archivo o a un directorio y, en el caso de los archivos, determinar
  su extensión.

  Con base en esta información, el módulo decide si debe delegar el procesamiento a
  un módulo handler específico según el tipo de archivo (.csv, .json o .log), procesar
  recursivamente el contenido de un directorio o regresar un error cuando la entrada
  es inválida o la extensión no es soportada.

  Este módulo es como un coordinador del flujo secuencial, al igual que los otros modulos es importante ya que con el mantenemos separada la responsabilidad de validar archivos y la lógica de parsear y obtener las métricas de cada tipo de archivo (.csv, .json, .log) lo cual se encargan otros módulos

### handlers

Dentro de esta carpeta se encuentran los módulos encargados de manejar el flujo de
procesamiento específico para cada tipo de archivo soportado en el proyecto
(.csv, .json y .log).

Cada uno de estos módulos es invocado desde  (secuential.ex) 
una vez que se ha validado la ruta y determinado que el archivo tiene una extensión
soportada. La responsabilidad de estos módulos no es realizar el procesamiento
completo, sino otra vez coordinar las distintas etapas necesarias para un tipo de archivo
específico.

El flujo que manejan estos módulos es el siguiente:
- Delegar el parseo del archivo al módulo parser correspondiente
- Recibir las métricas generadas a partir del contenido del archivo
- Construir el reporte utilizando el módulo Reporter
- Guardar el reporte generado en texto plano

Al igual que antes esta decision fué pensada para que por ejemplo si en un futuro un archivo debe de pasar por otro proceso simplemente en cada uno de estos modulos se agrega otra funcion llamando a un nuevo modulo que se encargará de dicha nueva implementación, y de esta manera se sigue manteniendo en orden el flujo que deben de seguir los archivos para su procesamiento

### parsers

En esta carpeta se encuentran los módulos responsables del parseo de los archivos
soportados por el proyecto (.csv, .json y .log).

Cada parser se encarga de leer y transformar el contenido del archivo en estructuras que puedan ser procesadas, así como de calcular todas las métricas solicitadas para ese tipo de archivo. Estas métricas se van acumulando y,
una vez finalizado el procesamiento, se retornan como resultado.

Nuevamente esto es importante porque cada uno de estos módulos únicamente se van a encargar de leer y tranformar los datos y producir las métricas necesarias, las cuales despues van a ser utilizadas por los módulos handler para darselas al módulo de hacer el reporte.
De esta manera si en el futuro se quieren realizar nuevas métricas únicamente hay que cambiar estos módulos


### parallel/coordinator.ex

Este módulo sirve como el coordinador del procesamiento paralelo de archivos.
Su responsabilidad es organizar, lanzar y supervisar la ejecución
concurrente de múltiples archivos utilizando procesos independientes.

Por ejemplo:

Cuando se recibe un directorio como entrada, el coordinador obtiene la lista
de archivos contenidos en él (File.ls) y los transforma en rutas completas. Después,
estos archivos se llevan a procesamiento paralelo mediante el uso del módulo
Task que ya viene con Elixir.

Decidí Task ya que proporciona una manera sencilla y segura para el manejo de concurrencia, permitiendo crear procesos sin necesidad de realizar manualmente funciones como spawn, send y receive. Ya que con cada llamada a Task.async/1 se crea un proceso y hace uso de estas funciones automaticamente y se encarga tambien de 
procesar un archivo de forma aislada.

Cada tarea o digamos procedimiento de procedimiento de los archivos la delegamos módulo FileProcessor.Sequential,
y esto permite reutilizar  la misma lógica de procesamiento utilizada en el modo secuencial, es decir lo que tenia que ver con validar la ruta y obtener los detalles como la extension y todo esto garantiza consistencia ya que ambos enfoques se hacen internamente de la misma manera y tambien evitamos duplicación de código.

El coordinador también es responsable de:
 Recolectar los resultados de todas las tareas creadas
 Manejar posibles errores o timeouts con Task.await/2
 Mostrar un indicador de progreso en tiempo real conforme los archivos son procesados

El uso de Task.await/2 con un tiempo límite nos permite evitar que por ejemplo
en caso de que algún proceso falle o tarde demasiado en completarse, simplemente mate a ese proceso y continue con los demás en lugar de quedarse atorado en él lo cual hace que todo sea más controlado.



# Futuras mejoras (Entrega 3)


## Manejo avanzado de errores y timeouts

Actualmente se cuenta con un manejo básico de timeouts en el procesamiento paralelo.
Para la siguiente entrega, se va a permitir que el usuario configure el tiempo máximo
de ejecución permitido para cada proceso, esto con parámetros de entrada a las funciones principales


## Manejo de archivos corruptos

Se van a agregar validaciones  durante el proceso de parseo para
detectar archivos corruptos o con formato inválido para que cuando tengamos  estos casos, el sistema
no se detenga si no que se registren los fallos y continuar
con el resto de los archivos.

Los archivos que no puedan ser procesados correctamente serán incluidos en el
reporte final como archivos fallidos, junto con la razón del error.

## Reintentos automáticos

Se va a implementar un sistema de reintentos
automáticos para aquellos archivos cuyo procesamiento falle debido a errores como timeouts o algunos fallos en la lectura


### Logging de errores

Se va realizar  un sistema de logging que permita registrar errores de manera
detallada, incluyendo:
 Tipo de error
 Archivo afectado
 Fecha y hora del fallo
 etc


### Ejecutable

Para la siguiente entrega del proyecto, nuestro programa se va a  converti en una herramienta ejecutable desde la línea de comandos, para que no haya necesidad necesidad de escribir iex -S mix

Esto permitirá ejecutar el proyecto con lineas de comando mas amigables para el usuario













