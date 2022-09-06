defmodule ExAudit.Type.Schema do
  use Ecto.Type

  def cast(schema) when is_atom(schema) do
    case Enum.member?(ExAudit.tracked_schemas(), schema) do
      true -> {:ok, schema}
      _ -> :error
    end
  end

  def cast(schema) when is_binary(schema) do
    load(schema)
  end

  def cast(_), do: :error

  def load(schema) do
    case get_schema_by_table(schema) do
      nil -> :error
      schema -> {:ok, schema}
    end
  end

  def dump(schema) do
    case Enum.member?(ExAudit.tracked_schemas(), schema) do
      true -> {:ok, schema.__schema__(:source)}
      _ -> :error
    end
  end

  defp get_schema_by_table(table) do
    ExAudit.tracked_schemas()
    |> Enum.find(fn schema ->
      schema.__schema__(:source) == table
    end)
  end

  def type, do: :string
end
