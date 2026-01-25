# File Processor - Procesamiento de Archivos en Elixir 

# Descripción

En este proyecto se implementa un sistema de procesamiento de archivos en Elixir que es capaz de analizar  
archivos con extensiones .csv, .json y .log, de los cuales se extraen métricas relevantes de cada uno y se generan los reportes correspondientes en texto plano.

Este sistema puede utilizarse tanto para procesamiento secuencial como paralelo, lo que nos permite comparar el rendimiento entre uno y otro.

Además, el proyecto incluye un ejecutable, por lo que ya no es necesario abrir iex para ejecutar las funciones.

# Ejecución

## Usando IEx (Opcional)

Este proyecto puede ejecutarse directamente desde iex accediendo a la carpeta del proyecto y ejecutando el comando

iex -S mix

Ejemplo:  
~/file_processor$ iex -S mix

## Usando el ejecutable (Recomendado)

Adicionalmente, el proyecto puede ejecutarse directamente desde la consola de línea de comandos con la siguiente estructura

./file_processor <function> <arguments>

<function>: es la función que deseas llamar del módulo FileProcessor (process_secuential, process_parallel, benchmark) 

<arguments>: Ruta al archivo, lista de archivos o directorio a procesar. Usa comillas si hay espacios en las rutas.


# Uso

## Uso con el comando iex -S mix

Una vez que el proyecto ha iniciado con el comando (iex -S mix), puedes hacer uso del módulo "FileProcessor" para procesar uno o múltiples archivos o un directorio completo.

### Procesamiento Secuencial

Para procesar uno o más archivos o un directorio de manera secuencial, se puede usar la función "process_secuential/1" de la siguiente manera:

Para procesar un solo archivo:  
FileProcessor.process_secuential("data/valid/ventas_enero.csv")

Para procesar múltiples archivos:  
archivos = ["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]  
FileProcessor.process_secuential(archivos)

Para procesar un directorio completo:  
FileProcessor.process_secuential("data/valid")

El procesamiento secuencial procesa y analiza los archivos uno por uno.

### Procesamiento Paralelo

Para procesar múltiples archivos o un directorio completo en paralelo, se puede usar la función "FileProcessor.process_parallel/1" de la siguiente manera:

Para procesar múltiples archivos:  
archivos = ["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]  
FileProcessor.process_parallel(archivos)

Para procesar un directorio completo:  
FileProcessor.process_parallel("data/valid")

El procesamiento paralelo crea múltiples procesos usando Task.async/1, lo que permite ejecutar varios archivos de manera concurrente.

Durante el procesamiento paralelo, se muestra un indicador de progreso que indica cuántos archivos han sido procesados.

Cada archivo procesado, ya sea de forma secuencial o paralela, devuelve un resultado (tupla) con la siguiente estructura:

{:ok, :processed_file_extension, reporter_path} : En caso de que se haya procesado correctamente

{:partial,:processed_file_extension, file_path} : En caso de que el archivo tenga informacion o estructura erronea

{:error, :processed_file_extension, file_parh} : En caso de que el archivo o directorio no se haya podido procesar

Para el procesamiento paralelo, los resultados se recopilan una vez que todos los procesos han finalizado su ejecución.

## Uso con el ejecutable

### Procesamiento secuencial

Procesamiento secuencial de un solo archivo:  
./file_processor process_secuential "data/valid/ventas_enero.csv"

Procesamiento secuencial de múltiples archivos:  
./file_processor process_secuential '["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]'

Procesamiento secuencial de un directorio completo:  
./file_processor process_secuential "data/valid"

### Procesamiento Paralelo

Procesamiento paralelo de múltiples archivos:  
./file_processor process_parallel '["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]'

Procesamiento paralelo de un directorio completo:  
./file_processor process_parallel "data/valid"

### Benchmark

Benchmark: comparación de tiempos de ejecución secuencial vs paralelo:  
./file_processor benchmark "data/valid"


Todas las rutas son relativas a la ubicación del ejecutable.




# Explicación de decisiones de diseño

## Estructura del proyecto

Decidí construir el proyecto de forma modular, por costumbre de cómo trabajé en proyectos Java, con el objetivo de separar claramente las responsabilidades de cada módulo y de cada carpeta que existe en el proyecto, lo que me permite trabajar de una manera más rápida y, en mi consideración, más limpia.

La estructura actual del proyecto es la siguiente:

lib/  
├── cli.ex  
├── error_logger.ex
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

Con esta estructura, lo que se hizo fue separar la lógica de todo lo involucrado en el procesamiento de archivos, haciendo que cada módulo y cada carpeta tengan una responsabilidad clara.

### cli.ex

El módulo FileProcessor.CLI convierte el proyecto en un ejecutable que puede ser utilizado desde la terminal.  
Su función principal es recibir argumentos desde la línea de comandos, interpretar qué función del módulo FileProcessor debe ejecutarse y con qué parámetros, y posteriormente llamar a dicha función.

Esto permite que ya no sea necesario abrir IEx para procesar archivos; basta con escribir el comando desde la terminal.

### file_processor.ex

Este módulo está destinado a ser la API pública donde se encuentran las funciones que el usuario utilizará directamente para procesar archivos de manera secuencial o paralela. Principalmente ayuda a que el usuario no necesite conocer los detalles de cómo funciona cada procedimiento y, de esta manera, exista una interfaz clara para el usuario.

### reporter.ex

Este módulo es responsable de construir los reportes de los archivos una vez que han sido procesados. Esto permite que este módulo simplemente se encargue de recibir las métricas obtenidas de los archivos procesados y construir el reporte a partir de ellas sin conocer cómo se obtuvieron dichas métricas ni todo lo que se tuvo que hacer para obtenerlas; simplemente las utiliza para construir un reporte.

### secuential.ex

Este módulo funciona como un coordinador para el procesamiento secuencial de archivos y directorios.

Su función principal es recibir una ruta como entrada y ejecutar una serie de pasos (usando el operador pipe) encadenados que permiten validar la existencia de la ruta, identificar si corresponde a un archivo o a un directorio y, en el caso de los archivos, determinar su extensión.

Con base en esta información, el módulo decide si debe delegar el procesamiento a un módulo handler específico de acuerdo con el tipo de archivo (.csv, .json o .log), procesar el contenido de un directorio de manera recursiva o devolver un error cuando la entrada es inválida o la extensión no es soportada.

Este módulo actúa como un coordinador del flujo secuencial. Al igual que los otros módulos, es importante porque mantiene separada la responsabilidad de validar archivos de la lógica de parseo y obtención de métricas para cada tipo de archivo (.csv, .json, .log), la cual es manejada por otros módulos.

### handlers

Dentro de esta carpeta se encuentran los módulos responsables de manejar el flujo de procesamiento específico para cada tipo de archivo soportado por el proyecto (.csv, .json y .log).

Cada uno de estos módulos es invocado desde (secuential.ex) una vez que la ruta ha sido validada y se ha determinado que el archivo tiene una extensión soportada. La responsabilidad de estos módulos no es realizar el procesamiento completo, sino nuevamente coordinar las diferentes etapas necesarias para un tipo de archivo específico.

El flujo manejado por estos módulos es el siguiente:
- Delegar el parseo del archivo al módulo parser correspondiente
- Recibir las métricas generadas a partir del contenido del archivo
- Construir el reporte usando el módulo Reporter
- Guardar el reporte generado en texto plano

Como antes, esta decisión se tomó para que, por ejemplo, si en el futuro un archivo necesita pasar por otro proceso, simplemente se pueda agregar otra función en cada uno de estos módulos llamando a un nuevo módulo que se encargue de esa nueva implementación y, de esta manera, el flujo de procesamiento se mantenga organizado.

### parsers

En esta carpeta se encuentran los módulos responsables de parsear los archivos soportados por el proyecto (.csv, .json y .log).

Cada parser es responsable de leer y transformar el contenido del archivo en estructuras que puedan ser procesadas, así como de calcular todas las métricas solicitadas para ese tipo de archivo. Estas métricas se van acumulando y, una vez que el procesamiento ha finalizado, se devuelven como resultado.

Nuevamente, esto es importante porque cada uno de estos módulos únicamente será responsable de leer y transformar los datos y producir las métricas necesarias, las cuales posteriormente serán utilizadas por los módulos handler para pasarlas al módulo encargado de construir el reporte.  
De esta forma, si en el futuro se requieren nuevas métricas, únicamente estos módulos deberán ser modificados.

### parallel/coordinator.ex

Este módulo funciona como el coordinador para el procesamiento paralelo de archivos.  
Su responsabilidad es organizar, lanzar y supervisar la ejecución concurrente de múltiples archivos utilizando procesos independientes.

Por ejemplo:

Cuando se recibe un directorio como entrada, el coordinador obtiene la lista de archivos contenidos en él (File.ls) y los transforma en rutas completas. Posteriormente, estos archivos son enviados a procesamiento paralelo utilizando el módulo Task que viene integrado en Elixir.

Elegí Task porque proporciona una manera simple y segura de manejar concurrencia, permitiendo crear procesos sin la necesidad de manejar manualmente funciones como spawn, send y receive. Con cada llamada a Task.async/1 se crea un proceso y estas funciones se utilizan automáticamente, además de que cada proceso es responsable de procesar un archivo de manera aislada.

Cada tarea, o digamos cada procedimiento de procesamiento de archivos, es delegada al módulo FileProcessor.Sequential, lo que permite reutilizar la misma lógica de procesamiento utilizada en el modo secuencial. Es decir, todo lo relacionado con la validación de la ruta y la obtención de detalles como la extensión. Esto garantiza consistencia, ya que ambos enfoques se manejan internamente de la misma manera y también evita la duplicación de código.

El coordinador también es responsable de:
- Recopilar los resultados de todas las tareas creadas
- Manejar posibles errores o timeouts con Task.await/2
- Mostrar un indicador de progreso en tiempo real conforme los archivos son procesados

El uso de Task.await/2 con un límite de tiempo nos permite evitar casos en los que, por ejemplo, si un proceso falla o tarda demasiado en completarse, dicho proceso simplemente se termina y la ejecución continúa con los demás en lugar de quedarse bloqueada, lo que hace que todo sea más controlado.


# FileProcessor CLI – Guía de Uso

El ejecutable `FileProcessor` proporciona una interfaz de línea de comandos (CLI) que permite procesar archivos sin abrir IEx.

Todos los comandos siguen la estructura general:

./file_processor <command> <path> [options]

Donde:
- `<command>` es la operación a ejecutar
- `<path>` es la ruta a un archivo o directorio
- `[options]` son parámetros opcionales en formato `key=value`

---

## process_secuential

Procesa un solo archivo, una lista de archivos o un directorio **de forma secuencial**.

### Sintaxis

./file_processor process_secuential <path>

### Ejemplos

Procesar un solo archivo:
./file_processor process_secuential "data/valid/ventas_enero.csv"

Procesar un directorio completo:
./file_processor process_secuential "data/valid"

## process_parallel 

Procesa archivos en paralelo, utilizando múltiples procesos concurrentes.

### Sintaxis

./file_processor process_parallel <path> [key=value ...]

### Opciones opcionales

max_workers – Número máximo de procesos trabajadores concurrentes

timeout – Tiempo máximo (en milisegundos) permitido por archivo


### Ejemplos 

Procesar un directorio usando opciones por defecto:
./file_processor process_parallel "data/valid"

Procesar un directorio con opciones personalizadas:
./file_processor process_parallel "data/valid" max_workers=3 timeout=10000

### Descripción

Cada archivo es procesado en un proceso independiente utilizando el módulo Task de Elixir.
Este modo mejora el rendimiento al manejar múltiples archivos.

Las opciones deben proporcionarse sin corchetes, sin comas y utilizando el formato key=value.

## benchmark

Compara el tiempo de ejecución del procesamiento secuencial vs paralelo.

### Sintaxis

./file_processor benchmark <path>

### Ejemplo

./file_processor benchmark "data/valid"

### Ejemplo de salida

Secuential time : 15000  
Parallel Time: 5000

### Descripción

Este comando ejecuta internamente ambos modos de procesamiento e imprime el tiempo de ejecución en microsegundos, permitiendo una comparación directa de rendimiento.

## Comando de ayuda

Muestra la información de uso del CLI.

### Sintaxis

./file_processor --help

## Notas

Todas las rutas se resuelven de manera relativa a la ubicación del ejecutable

Si una ruta contiene espacios, debe ir entre comillas

Las opciones solo son soportadas para process_parallel

## Errores comunes y solución de problemas

Esta sección describe errores comunes al usar el ejecutable FileProcessor
y cómo solucionarlos.

### 1. Usar corchetes para las opciones del CLI

Incorrecto:
./file_processor process_parallel "data/valid" [max_workers=3, timeout=10000]

Correcto:
./file_processor process_parallel "data/valid" max_workers=3 timeout=10000

### 2. Usar comas entre opciones 

Incorrecto:
./file_processor process_parallel "data/valid" max_workers=3, timeout=10000

Correcto:
./file_processor process_parallel "data/valid" max_workers=3 timeout=10000

### 3. Olvidar comillas en rutas con espacios

Incorrecto:
./file_processor process_secuential data/my files

Correcto

./file_processor process_secuential "data/my files"

Siempre coloca las rutas entre comillas si contienen espacios.

### 4. Ejecutar el ejecutable desde el directorio incorrecto

Incorrecto:
./file_processor process_secuential data/valid


Correcto
cd file_processor
./file_processor process_secuential data/valid


Todas las rutas relativas se resuelven desde el directorio donde se ejecuta el ejecutable.

### 5. Olvidar permisos de ejecución

Usar una extensión de archivo no soportada

Incorrecto:
./file_processor process_secuential "data/file.txt"

Correcto:

Extensiones soportadas:

.csv

.json

.log

Los archivos con extensiones no soportadas devolverán un mensaje de error.


### 6. Pasar valores inválidos en las opciones

Incorrecto:
./file_processor process_parallel "data/valid" max_workers=abc

Correcto:

./file_processor process_parallel "data/valid" max_workers=4

Las opciones numéricas deben contener valores enteros válidos.

### 7. Mezclar el uso de IEx con el uso del CLI

Correcto(CLI):
./file_processor process_secuential "data/valid"

Correcto(IEx):
FileProcessor.process_secuential("data/valid")









# File Processor - File Processing in Elixir 

# Description

In this project, a file processing system is implemented in Elixir which is capable of analyzing  
files with extensions .csv, .json, and .log, from which relevant metrics are extracted from each one and corresponding reports are generated in plain text.

This system can be used for both sequential and parallel processing, which allows us to compare the performance between one and the other.

Additionally, the project includes an executable, so it is no longer necessary to open iex to execute the functions.

# Execution

## Using IEx (Optional)

This project can be executed directly from iex by accessing the project folder and running the command

iex -S mix

Example:  
~/file_processor$ iex -S mix

## Using the executable (Recommended)

Additionally, the project can be executed directly from the command line console with the following structure

./file_processor <function> <arguments>

<function>: is the function that you want to call from the FileProcessor module (process_secuential, process_parallel, benchmark) 

<arguments>: Path to the file, list of files, or directory to be processed. Use quotes if there are spaces in the paths.


# Usage

## Usage with the iex -S mix command

Once the project has started with the command (iex -S mix), you can make use of the "FileProcessor" module to process one or multiple files or an entire directory.

### Sequential Processing

To process one or more files or a directory sequentially, the "process_secuential/1" function can be used as follows:

To process a single file:  
FileProcessor.process_secuential("data/valid/ventas_enero.csv")

To process multiple files:  
archivos = ["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]  
FileProcessor.process_secuential(archivos)

To process an entire directory:  
FileProcessor.process_secuential("data/valid")

Sequential processing processes and analyzes files one by one.

### Parallel Processing

To process multiple files or an entire directory in parallel, the "FileProcessor.process_parallel/1" function can be used as follows:

To process multiple files:  
archivos = ["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]  
FileProcessor.process_parallel(archivos)

To process an entire directory:  
FileProcessor.process_parallel("data/valid")

Parallel processing creates multiple processes using Task.async/1, which allows multiple files to be executed concurrently.

During parallel processing, a progress indicator is shown indicating how many files have been processed.

Each processed file, whether sequentially or in parallel, returns a result (tuple) with the following structure:

{:ok, :processed_file_extension} : In case it was processed successfully

{:error, reason} : In case the file or directory could not be processed

For parallel processing, the results are collected once all processes have finished execution.

## Usage with the executable

### Sequential processing

Sequential processing of a single file:  
./file_processor process_secuential "data/valid/ventas_enero.csv"

Sequential processing of multiple files:  
./file_processor process_secuential '["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]'

Sequential processing of an entire directory:  
./file_processor process_secuential "data/valid"

### Parallel Processing

Parallel processing of multiple files:  
./file_processor process_parallel '["data/valid/ventas_enero.csv","data/valid/ventas_febrero.csv","data/valid/sesiones.json"]'

Parallel processing of an entire directory:  
./file_processor process_parallel "data/valid"

### Benchmark

Benchmark: comparison of sequential vs parallel execution times:  
./file_processor benchmark "data/valid"


All paths are relative to the location of the executable.




# Explanation of design decisions

## Project structure

I decided to build the project in a modular way, due to habit from how I worked on Java projects, with the goal of clearly separating the responsibilities of each module and each folder that exists in the project, which allows me to work in a faster and, in my consideration, cleaner way.

The current structure of the project is as follows:

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

With this structure, what was done was to separate the logic of everything involved in file processing, making each module and each folder have a clear responsibility.

### cli.ex

The FileProcessor.CLI module turns the project into an executable that can be used from the terminal.  
Its main function is to receive arguments from the command line, interpret which function from the FileProcessor module should be executed and with which parameters, and then call that function.

This allows it to no longer be necessary to open IEx to process files; it is enough to type the command from the terminal.

### file_processor.ex

This module is intended to be the public API where the functions that the user will directly use to process files either sequentially or in parallel are located. It mainly helps so that the user does not need to know the details of how each procedure works, and in this way there is a clear interface for the user.

### reporter.ex

This module is responsible for building the reports of the files once they have been processed. This allows this module to simply be responsible for receiving the metrics obtained from the processed files and building the report from them without knowing how those metrics were obtained or everything that had to be done to obtain them; it simply uses them to build a report.

### secuential.ex

This module serves as a coordinator for sequential file and directory processing.

Its main function is to receive a path as input and execute a series of steps (using the pipe operator) chained together that allow validating the existence of the path, identifying whether it corresponds to a file or a directory and, in the case of files, determining their extension.

Based on this information, the module decides whether it should delegate processing to a specific handler module according to the file type (.csv, .json, or .log), process the contents of a directory recursively, or return an error when the input is invalid or the extension is not supported.

This module acts as a coordinator of the sequential flow. Like the other modules, it is important because it keeps the responsibility of validating files separate from the logic of parsing and obtaining metrics for each file type (.csv, .json, .log), which is handled by other modules.

### handlers

Within this folder are the modules responsible for handling the specific processing flow for each file type supported by the project (.csv, .json, and .log).

Each of these modules is invoked from (secuential.ex) once the path has been validated and it has been determined that the file has a supported extension. The responsibility of these modules is not to perform the complete processing, but once again to coordinate the different stages necessary for a specific file type.

The flow handled by these modules is as follows:
- Delegate file parsing to the corresponding parser module
- Receive the metrics generated from the file content
- Build the report using the Reporter module
- Save the generated report in plain text

As before, this decision was made so that, for example, if in the future a file needs to go through another process, simply another function can be added in each of these modules calling a new module that will handle that new implementation, and in this way the processing flow remains organized.

### parsers

In this folder are the modules responsible for parsing the files supported by the project (.csv, .json, and .log).

Each parser is responsible for reading and transforming the content of the file into structures that can be processed, as well as calculating all the requested metrics for that type of file. These metrics are accumulated and, once processing is complete, are returned as a result.

Again, this is important because each of these modules will only be responsible for reading and transforming the data and producing the necessary metrics, which will later be used by the handler modules to pass them to the report-building module.  
In this way, if new metrics are needed in the future, only these modules need to be changed.

### parallel/coordinator.ex

This module serves as the coordinator for parallel file processing.  
Its responsibility is to organize, launch, and supervise the concurrent execution of multiple files using independent processes.

For example:

When a directory is received as input, the coordinator obtains the list of files contained within it (File.ls) and transforms them into full paths. Then, these files are sent to parallel processing using the Task module that comes built into Elixir.

I chose Task because it provides a simple and safe way to handle concurrency, allowing processes to be created without the need to manually handle functions such as spawn, send, and receive. With each call to Task.async/1, a process is created and these functions are used automatically, and it is also responsible for processing a file in an isolated way.

Each task, or let's say each file processing procedure, is delegated to the FileProcessor.Sequential module, which allows reusing the same processing logic used in sequential mode. That is, everything related to validating the path and obtaining details such as the extension. This guarantees consistency since both approaches are internally handled in the same way and also avoids code duplication.

The coordinator is also responsible for:
- Collecting the results of all created tasks
- Handling possible errors or timeouts with Task.await/2
- Displaying a real-time progress indicator as files are processed

Using Task.await/2 with a time limit allows us to avoid cases where, for example, if a process fails or takes too long to complete, that process is simply terminated and execution continues with the others instead of getting stuck on it, which makes everything more controlled.


# FileProcessor CLI – Usage Guide

The `FileProcessor` executable provides a command-line interface (CLI) that allows processing files without opening IEx.

All commands follow the general structure:

./file_processor <command> <path> [options]

Where:
- `<command>` is the operation to execute
- `<path>` is a file or directory path
- `[options]` are optional parameters in `key=value` format

---

## process_secuential

Processes a single file, a list of files, or a directory **sequentially**.

### Syntax

./file_processor process_secuential <path>

### Examples

Process a single file:
./file_processor process_secuential "data/valid/ventas_enero.csv"

Process an entire directory:
./file_processor process_secuential "data/valid"

## Process_parallel 

Processes files in parallel, using multiple concurrent processes.

### Syntax

./file_processor process_parallel <path> [key=value ...]

### Optional options

max_workers – Maximum number of concurrent worker processes

timeout – Maximum time (in milliseconds) allowed per file


### Examples 

Process a directory using default options:
./file_processor process_parallel "data/valid"

Process a directory with custom options:
./file_processor process_parallel "data/valid" max_workers=3 timeout=10000

### Description

Each file is processed in an independent process using Elixir’s Task module.
This mode improves performance when handling multiple files.

Options must be provided without brackets, without commas, and using the key=value format.

## benchmark

Compares the execution time of sequential vs parallel processing.

### Syntax

./file_processor benchmark <path>

### Example

./file_processor benchmark "data/valid"

### Output example

Secuential time : 15000
Parallel Time: 5000

### Description

This command runs both processing modes internally and prints the execution time in microseconds, allowing a direct performance comparison.

## Help Comand

Displays usage information for the CLI.

### Syntax

./file_processor --help

## Notes

All paths are resolved relative to the location of the executable

If a path contains spaces, it must be wrapped in quotes

Options are only supported for process_parallel

## Common mistakes and troubleshooting

This section describes common mistakes when using the FileProcessor executable
and how to fix them.

### 1. Using brackets for CLI options

 Incorrect:
./file_processor process_parallel "data/valid" [max_workers=3, timeout=10000]

Correct:
./file_processor process_parallel "data/valid" max_workers=3 timeout=10000

### 2. Using commas between options 

Incorrect:
./file_processor process_parallel "data/valid" max_workers=3, timeout=10000

Correct:
./file_processor process_parallel "data/valid" max_workers=3 timeout=10000

### 3. Forgetting quotes around paths with spaces

Incorrect:
./file_processor process_secuential data/my files

Correct

./file_processor process_secuential "data/my files"

Always wrap paths in quotes if they contain spaces.

### 4. Running the executable from the wrong directory

Incorrect:
./file_processor process_secuential data/valid


Correct
cd file_processor
./file_processor process_secuential data/valid


All relative paths are resolved from the directory where the executable is run.

### 5. Forgetting execution permissions

Using an unsupported file extension

Incorrect:
./file_processor process_secuential "data/file.txt"

Correct:

Supported extensions:

.csv

.json

.log

Files with unsupported extensions will return an error message.


### 6.Passing invalid option values

Incorrect:
./file_processor process_parallel "data/valid" max_workers=abc

Correct:

./file_processor process_parallel "data/valid" max_workers=4

Numeric options must contain valid integer values.

### 7. Mixing IEx usage with CLI usage

Correct(CLI):
./file_processor process_secuential "data/valid"

Correct(IEx);
FileProcessor.process_secuential("data/valid")





