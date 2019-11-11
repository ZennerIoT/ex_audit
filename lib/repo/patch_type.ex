defmodule ExAudit.Type.Patch do
  @behaviour Ecto.Type

  def cast(a), do: {:ok, a}
  def dump(patch), do: {:ok, :erlang.term_to_binary(patch)}
  def load(binary), do: {:ok, :erlang.binary_to_term(binary)}
  def type, do: :binary

  def embed_as(_), do: :self
  def equal?(term1, term2), do: term1 == term2
  defoverridable embed_as: 1, equal?: 2
end
