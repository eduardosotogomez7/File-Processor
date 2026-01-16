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





