defmodule ExAudit.Tracking do
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

    if schema in tracked_schemas() do
      assocs = schema.__schema__(:associations)

      patch = ExAudit.Diff.diff(
        ExAudit.Tracker.map_struct(old) |> Map.drop(assocs),
        ExAudit.Tracker.map_struct(new) |> Map.drop(assocs)
      )

      case patch do
        :not_changed -> []
        patch ->
          params = %{
            entity_id: Map.get(old, :id) || Map.get(new, :id),
            entity_schema: schema,
            patch: patch,
            action: action
          }

          [params]
      end
    else
      []
    end
  end

  def track_change(module, action, changeset, resulting_struct, opts) do
    if not Keyword.get(opts, :ignore_audit, false) do
      changes = find_changes(action, changeset, resulting_struct)

      insert_versions(module, changes, opts)
    end
  end

  def insert_versions(module, changes, opts) do
    now = DateTime.utc_now()

    custom_fields =
      Keyword.get(opts, :ex_audit_custom, [])
      |> Enum.into(%{})

    changes =
      Enum.map(changes, fn change ->
        change = Map.put(change, :recorded_at, now)
        Map.merge(change, custom_fields)
      end)

    case changes do
      [] ->
        :ok

      _ ->
        module.insert_all(version_schema(), changes, opts)
    end
  end

  def find_assoc_deletion(module, struct, repo_opts) do
    struct =
      case struct do
        %Ecto.Changeset{} -> Ecto.Changeset.apply_changes(struct)
        _ -> struct
      end

    schema = struct.__struct__

    assocs =
      schema.__schema__(:associations)
      |> Enum.map(fn field -> {field, schema.__schema__(:association, field)} end)
      |> Enum.filter(fn {_, opts} -> Map.get(opts, :on_delete) == :delete_all end)

    assocs
    |> Enum.flat_map(fn {field, _opts} ->
      root = module.all(Ecto.assoc(struct, field))
      root ++ Enum.map(root, &find_assoc_deletion(module, &1, repo_opts))
    end)
    |> List.flatten()
    |> Enum.flat_map(&compare_versions(:deleted, &1, %{}))
  end

  def track_assoc_deletion(module, struct, opts) do
    deleted_structs = find_assoc_deletion(module, struct, opts)

    insert_versions(module, deleted_structs, opts)
  end

  defp tracked_schemas do
    Application.get_env(:ex_audit, :tracked_schemas)
  end

  defp version_schema do
    Application.get_env(:ex_audit, :version_schema)
  end
end
