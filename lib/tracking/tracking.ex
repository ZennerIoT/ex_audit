defmodule ExAudit.Tracking do
  @version_schema Application.get_env(:ex_audit, :version_schema)
  @ignored_fields [:__meta__, :__struct__]

  import Ecto.Query

  def find_changes(action, struct_or_changeset, resulting_struct) do
    old = case {action, struct_or_changeset} do
      {:created, _} -> %{}
      {_, %Ecto.Changeset{data: struct}} -> struct
      {_, %{} = struct} -> struct
      {_, nil} -> %{}
    end

    new = case action do
      x when x in [:updated, :created] -> 
        resulting_struct
      :deleted -> %{}
    end

    compare_versions(action, old, new)
  end

  def compare_versions(action, old, new) do
    schema = Map.get(old, :__struct__, Map.get(new, :__struct__))

    assocs = schema.__schema__(:associations)

    ignored_fields = @ignored_fields ++ assocs

    patch = ExAudit.Diff.diff(Map.drop(old, ignored_fields), Map.drop(new, ignored_fields))

    params = %{
      entity_id: Map.get(old, :id) || Map.get(new, :id),
      entity_schema: schema,
      patch: patch,
      action: action
    }

    [params]
  end

  def track_change(module, adapter, action, changeset, resulting_struct, opts) do
    changes = find_changes(action, changeset, resulting_struct)

    insert_versions(module, adapter, changes, opts)
  end

  def insert_versions(module, adapter, changes, opts) do
    now = DateTime.utc_now
    custom_fields = 
      Keyword.get(opts, :ex_audit_custom, [])
      |> Enum.into(%{})

    changes = Enum.map(changes, fn change ->
      change = Map.put(change, :recorded_at, now)
      Map.merge(change, custom_fields)
    end)

    case changes do
      [] -> :ok
      _ ->
        Ecto.Repo.Schema.insert_all(module, adapter, @version_schema, changes, opts)
    end
  end

  def find_assoc_deletion(module, adapter, struct, repo_opts) do
    schema = case struct do
      %Ecto.Changeset{data: %{__struct__: schema}} -> schema
      %{__struct__: schema} -> schema
    end

    id = case struct do
      %Ecto.Changeset{data: %{id: id}} -> id
      %{id: id} -> id
    end

    assocs = 
      schema.__schema__(:associations) 
      |> Enum.map(fn field -> {field, schema.__schema__(:association, field)} end)
      |> Enum.filter(fn {_, opts} -> Map.get(opts, :on_delete) == :delete_all end)
 
    assocs
    |> Enum.flat_map(fn {field, opts} -> 
      assoc_schema = Map.get(opts, :related)

      filter = [{Map.get(opts, :related_key), id}]

      query = 
        from(s in assoc_schema)
        |> where(^filter)

      root = module.all(query)
      root ++ Enum.map(root, &find_assoc_deletion(module, adapter, &1, repo_opts))
    end)
    |> List.flatten()
    |> Enum.flat_map(&compare_versions(:deleted, &1, %{}))
  end

  def track_assoc_deletion(module, adapter, struct, opts) do
    deleted_structs = find_assoc_deletion(module, adapter, struct, opts)

    insert_versions(module, adapter, deleted_structs, opts)
  end
end