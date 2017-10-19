defmodule ExAudit.Queryable do
  @version_schema Application.get_env(:ex_audit, :version_schema)

  def update_all(module, adapter, queryable, updates, opts) do
    Ecto.Repo.Queryable.update_all(module, adapter, queryable, updates, opts)
  end

  def delete_all(module, adapter, queryable, opts) do
    Ecto.Repo.Queryable.delete_all(module, adapter, queryable, opts)
  end

  def history(module, adapter, queryable, opts) do
    import Ecto.Query

    query = from v in @version_schema, 
      order_by: v.recorded_at

    # TODO what do when we get a query

    query = case queryable do
      # %Ecto.Query{from: struct} -> 
      #   from v in query, 
      #     where: v.entity_id == subquery(from q in queryable, select: q.id),
      #     where: v.entity_schema == ^struct
      %{__struct__: struct, id: id} when nil not in [struct, id] ->
        from v in query, 
          where: v.entity_id == ^id, 
          where: v.entity_schema == ^struct
    end

    Ecto.Repo.Queryable.all(module, adapter, query, opts)
  end
end