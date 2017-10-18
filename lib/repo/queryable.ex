defmodule ExAudit.Queryable do
  def update_all(module, adapter, queryable, updates, opts) do
    Ecto.Repo.Queryable.update_all(module, adapter, queryable, updates, opts)
  end

  def delete_all(module, adapter, queryable, opts) do
    Ecto.Repo.Queryable.delete_all(module, adapter, queryable, opts)
  end

  def history(module, adapter, queryable, id, opts) do
    # TODO implement
  end
end