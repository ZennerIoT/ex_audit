defmodule ExAudit.Tracking do
  @version_schema Application.get_env(:ex_audit, :version_schema)
  @ignored_fields [:__meta__, :__struct__]

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

  def compare_versions(guessed_action, old, new) do
    schema = Map.get(old, :__struct__, Map.get(new, :__struct__))

    assocs = schema.__schema__(:associations)

    ignored_fields = @ignored_fields ++ assocs

    patch = ExAudit.Diff.diff(Map.drop(old, ignored_fields), Map.drop(new, ignored_fields))

    guessed_action = guessed_action || guess_action(old, new)

    params = %{
      entity_id: Map.get(old, :id) || Map.get(new, :id),
      entity_schema: schema,
      patch: patch,
      action: guessed_action
    }

    [params]
  end

  def guess_action(%{id: id}, %{id: id}) when not is_nil(id), do: :updated
  def guess_action(%{}, %{id: id}) when not is_nil(id), do: :created
  def guess_action(%{id: id}, nil) when not is_nil(id), do: :deleted

  def track_change(module, adapter, action, changeset, resulting_struct, opts) do
    changes = find_changes(action, changeset, resulting_struct)

    now = DateTime.utc_now
    custom_fields = Keyword.get(opts, :ex_audit_custom, []) |> Enum.into(%{})

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
end