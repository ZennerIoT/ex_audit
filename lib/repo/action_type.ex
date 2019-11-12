defmodule ExAudit.Type.Action do
  use Ecto.Type

  @actions ~w[created updated deleted]a

  for action <- @actions do
    def cast(unquote(Atom.to_string(action))) do
      {:ok, unquote(action)}
    end

    def cast(unquote(action)) do
      {:ok, unquote(action)}
    end

    def load(unquote(Atom.to_string(action))) do
      {:ok, unquote(action)}
    end

    def dump(unquote(action)) do
      {:ok, unquote(Atom.to_string(action))}
    end
  end

  def dump(_), do: :error
  def load(_), do: :error
  def cast(_), do: :error

  def type, do: :string
end
