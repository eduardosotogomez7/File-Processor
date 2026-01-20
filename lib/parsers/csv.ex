defmodule FileProcessor.Parser.CSV do
  @moduledoc """
  CSV file parser responsible for reading, validating, and analyzing sales data.

  This module reads a CSV file from disk, parses its content, validates each row,
  and generates structured information about the processed data. It separates
  valid rows from invalid ones, collects detailed validation errors, and computes
  business metrics when possible.

  ## Responsibilities

  - Read CSV file content from a given path.
  - Parse rows using `NimbleCSV`.
  - Validate each row structure and individual fields.
  - Separate valid lines from invalid lines with detailed error messages.
  - Determine the overall processing state (`:ok`, `:partial`, or `:error`).
  - Compute metrics such as total sales, best seller, and date range.

  ## Expected CSV format

  Each row must contain exactly six fields in the following order:

  1. Date (`DD/MM/YYYY`)
  2. Product name (non-empty string)
  3. Category
  4. Unit price (positive number)
  5. Quantity (positive integer)
  6. Discount (integer between 0 and 100)

  Rows that do not match this structure or contain invalid values are reported
  as errors.

  ## Return value

  On success, returns:

      {:ok, %{
        state: :ok | :partial | :error,
        processed_lines: integer(),
        valid_lines: integer(),
        error_lines: integer(),
        errors: list(),
        metrics: map()
      }}

  If the file cannot be read, returns:

      {:error, reason}

  This module does not perform any file output; it only parses and analyzes data.
  """

  def parse(path) do
    case File.read(path) do
      {:ok, content} ->
        rows = NimbleCSV.RFC4180.parse_string(content)

        {valid_lines, error_lines} =
          rows
          |> Enum.with_index(1)
          |> Enum.reduce({[], []}, fn {row, line}, {valid_lines, error_lines} ->
            case valid_line?({row, line}) do
              {:ok, valid_line} -> {[valid_line | valid_lines], error_lines}
              {:error, error_line} -> {valid_lines, [error_line | error_lines]}
            end
          end)

        valid_lines = Enum.reverse(valid_lines)
        error_lines = Enum.reverse(error_lines)

        metrics =
          case valid_lines do
            [] ->
              %{}

            _ ->
              %{
                total_sales: total_sold(valid_lines),
                unique_products: unique_products(valid_lines),
                best_seller: best_seller(valid_lines),
                best_category: best_category(valid_lines),
                average_amount: average_amount(valid_lines),
                date_range: date_range(valid_lines)
              }
          end

        state =
          cond do
            error_lines == [] -> :ok
            valid_lines == [] -> :error
            true -> :partial
          end

        {:ok,
         %{
           state: state,
           processed_lines: length(rows),
           valid_lines: length(valid_lines),
           error_lines: length(error_lines),
           errors: error_lines,
           metrics: metrics
         }}

        case state do
          :ok ->
            {:ok,
             %{
               state: state,
               processed_lines: length(rows),
               valid_lines: length(valid_lines),
               error_lines: length(error_lines),
               errors: error_lines,
               metrics: metrics
             }}

          :partial ->
            {:partial,
             %{
               state: state,
               errors: error_lines
             }}

          :error ->
            {:error,
             %{
               state: state,
               errors: error_lines
             }}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------------
  #    Valid Lines
  # -------------------------------------------------------------------------------------

  defp valid_line?({row, line}) do
    case row do
      [fecha, producto, categoria, precio_unitario, cantidad, descuento] ->
        validate_fields({fecha, producto, categoria, precio_unitario, cantidad, descuento}, line)

      _ ->
        {:error, {line, "Incomplete line or invalid format"}}
    end
  end

  defp validate_fields({fecha, producto, categoria, precio_unitario, cantidad, descuento}, line) do
    with {:ok, date} <- validate_date(fecha, line),
         {:ok, product} <- validate_product(producto, line),
         {:ok, price} <- validate_price(precio_unitario, line),
         {:ok, quantity} <- validate_quantity(cantidad, line),
         {:ok, discount} <- validate_discount(descuento, line) do
      {:ok, [date, product, categoria, price, quantity, discount]}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_date(fecha, line) when is_bitstring(fecha) do
    case String.split(fecha, "/") do
      [day, month, year] ->
        with {day, ""} <- Integer.parse(day),
             {month, ""} <- Integer.parse(month),
             {year, ""} <- Integer.parse(year),
             {:ok, date} <- Date.new(year, month, day) do
          {:ok, date}
        else
          _ ->
            {:error, {line, "Invalid date. Expected format DD/MM/YYYY"}}
        end

      _ ->
        {:error, {line, "Invalid date format. Expected DD/MM/YYYY"}}
    end
  end

  defp validate_date(_, line) do
    {:error, {line, "Date must be a string"}}
  end

  defp validate_product(producto, line) when is_bitstring(producto) do
    producto = String.trim(producto)

    if producto == "" do
      {:error, {line, "Product cannot be empty"}}
    else
      {:ok, producto}
    end
  end

  defp validate_product(_, line) do
    {:error, {line, "Product must be a string"}}
  end

  defp validate_price(price, line) when is_bitstring(price) do
    price = String.trim(price)

    cond do
      price == "" ->
        {:error, {line, "Price cannot be empty"}}

      true ->
        case Float.parse(price) do
          {value, ""} when value > 0 ->
            {:ok, value}

          {value, ""} when value <= 0 ->
            {:error, {line, "Price must be positive"}}

          _ ->
            {:error, {line, "Invalid price: #{price}"}}
        end
    end
  end

  defp validate_price(_, line) do
    {:error, {line, "Price must be a string"}}
  end

  defp validate_quantity(quantity, line) when is_bitstring(quantity) do
    quantity = String.trim(quantity)

    cond do
      quantity == "" ->
        {:error, {line, "Quantity cannot be empty"}}

      true ->
        case Integer.parse(quantity) do
          {value, ""} when value > 0 ->
            {:ok, value}

          {value, ""} when value <= 0 ->
            {:error, {line, "Quantity must be greater than zero"}}

          _ ->
            {:error, {line, "Invalid quantity: #{quantity}"}}
        end
    end
  end

  defp validate_quantity(_, line) do
    {:error, {line, "Quantity must be a string"}}
  end

  defp validate_discount(discount, line) when is_bitstring(discount) do
    discount = String.trim(discount)

    cond do
      discount == "" ->
        {:error, {line, "Discount cannot be empty"}}

      true ->
        case Integer.parse(discount) do
          {value, ""} when value >= 0 and value <= 100 ->
            {:ok, value}

          {value, ""} when value < 0 ->
            {:error, {line, "Discount cannot be negative"}}

          {value, ""} when value > 100 ->
            {:error, {line, "Discount cannot be greater than 100"}}

          _ ->
            {:error, {line, "Invalid discount: #{discount}"}}
        end
    end
  end

  defp validate_discount(_, line) do
    {:error, {line, "Discount must be a string"}}
  end

  # ------------------------------------------------------------------------
  # Total Sales
  # ------------------------------------------------------------------------
  defp total_sold(rows) when is_list(rows) do
    rows
    |> Enum.reduce(0, fn x, acc -> acc + sold_by_row(x) end)
  end

  defp sold_by_row([_fecha, _producto, _categoria, precio_unitario, cantidad, descuento]) do
    final_price = precio_unitario - precio_unitario * descuento / 100
    final_price * cantidad
  end

  # ---------------------------------------------------------------------------
  #  Unique Products
  # ---------------------------------------------------------------------------

  defp unique_products(rows) when is_list(rows) do
    rows
    |> Enum.map(fn [_fecha, producto, _categoria, _precio_unitario, _cantidad, _desceunto] ->
      producto
    end)
    |> Enum.uniq()
    |> length()
  end

  # ------------------------------------------------------------------------------
  # Best Seller
  # ------------------------------------------------------------------------------

  defp best_seller(rows) when is_list(rows) do
    rows
    |> Enum.map(fn [_fecha, producto, _categoria, _precio_unitario, cantidad, _descuento] ->
      {producto, cantidad}
    end)
    |> Enum.group_by(fn {producto, _cantidad} -> producto end)
    |> Enum.map(&quantity_by_product/1)
    |> Enum.max_by(fn {_product, total} -> total end)
  end

  defp quantity_by_product({product, values}) do
    total =
      values
      |> Enum.map(fn {_product, quantity} -> quantity end)
      |> Enum.sum()

    {product, total}
  end

  # ----------------------------------------------------------------------------------
  # Best Category
  # -----------------------------------------------------------------------------------

  defp best_category(rows) when is_list(rows) do
    rows
    |> Enum.group_by(fn [_fecha, _producto, categoria, _precio_unitario, _cantidad, _descuento] ->
      categoria
    end)
    |> Enum.map(fn {categoria, values} -> sold_by_category({categoria, values}) end)
    |> Enum.max_by(fn {_categoria, total} -> total end)
  end

  defp sold_by_category({categoria, values}) do
    total =
      values
      |> Enum.reduce(0, fn value, acc -> acc + sold_by_row(value) end)

    {categoria, total}
  end

  # --------------------------------------------------------------------------------
  # Average Amount
  # --------------------------------------------------------------------------------

  defp average_amount(rows) when is_list(rows) do
    total =
      rows
      |> Enum.map(fn [_fecha, _producto, _categoria, _precio_unitario, _cantidad, descuento] ->
        descuento
      end)
      |> Enum.sum()

    total / length(rows)
  end

  # -------------------------------------------------------------------------------
  # Date Range
  # ---------------------------------------------------------------------------------

  defp date_range(rows) when is_list(rows) do
    dates =
      rows
      |> Enum.map(fn [fecha | _] -> fecha end)

    {Enum.min(dates), Enum.max(dates)}
  end
end
