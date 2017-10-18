defmodule ExAudit.Schema do
  def insert_all(module, adapter, schema_or_source, entries, opts) do
    Ecto.Repo.Schema.insert_all(module, adapter, schema_or_source, entries, opts)
  end

  def insert(module, adapter, struct, opts) do
    Ecto.Repo.Schema.insert(module, adapter, struct, opts)
  end

  def update(module, adapter, struct, opts) do
    Ecto.Repo.Schema.update(module, adapter, struct, opts)
  end

  def insert_or_update(module, adapter, changeset, opts) do
    Ecto.Repo.Schema.insert_or_update(module, adapter, changeset, opts)
  end

  def delete(module, adapter, struct, opts) do
    Ecto.Repo.Schema.delete(module, adapter, struct, opts)
  end

  def insert!(module, adapter, struct, opts) do
    Ecto.Repo.Schema.insert!(module, adapter, struct, opts)
  end

  def update!(module, adapter, struct, opts) do
    Ecto.Repo.Schema.update!(module, adapter, struct, opts)
  end

  def insert_or_update!(module, adapter, changeset, opts) do
    Ecto.Repo.Schema.insert_or_update!(module, adapter, changeset, opts)
  end

  def delete!(module, adapter, struct, opts) do
    Ecto.Repo.Schema.delete!(module, adapter, struct, opts)
  end
end