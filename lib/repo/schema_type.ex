defmodule ExAudit.Type.Schema do
  @behaviour Ecto.Type

  @schemas Application.get_env(:ex_audit, :tracked_schemas, [])

  for schema <- @schemas do
    def cast(unquote(schema)), do: {:ok, unquote(schema)}
    def cast(unquote(schema.__schema__(:source))), do: {:ok, unquote(schema)}

    def load(unquote(schema.__schema__(:source))), do: {:ok, unquote(schema)}

    def dump(unquote(schema)), do: {:ok, unquote(schema.__schema__(:source))}
  end

  def cast(_), do: :error
  def load(_), do: :error
  def dump(_), do: :error

  def type, do: :string
end