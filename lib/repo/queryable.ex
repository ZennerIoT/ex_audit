defmodule ExAudit.Queryable do
  require Logger
  import Ecto.Query, only: [from: 2, where: 3]

  def update_all(module, queryable, updates, opts) do
    Ecto.Repo.Queryable.update_all(module, queryable, updates, opts)
  end

  def delete_all(module, queryable, opts) do
    Ecto.Repo.Queryable.delete_all(module, queryable, opts)
  end

  def history(module, struct, opts) do
    query =
      from(
        v in version_schema(module),
        order_by: [desc: :recorded_at]
      )

    # TODO what do when we get a query

    query =
      case struct do
        # %Ecto.Query{from: struct} ->
        #   from v in query,
        #     where: v.entity_id == subquery(from q in struct, select: q.id),
        #     where: v.entity_schema == ^struct
        %{__struct__: struct, id: id} when nil not in [struct, id] ->
          from(
            v in query,
            where: v.entity_id == ^id,
            where: v.entity_schema == ^struct
          )
      end

    versions = Ecto.Repo.Queryable.all(module, query, Ecto.Repo.Supervisor.tuplet(module, opts))

    if Keyword.get(opts, :render_struct, false) do
      {versions, oldest_struct} =
        versions
        |> Enum.map_reduce(struct, fn version, new_struct ->
          old_struct = _revert(version, new_struct)

          version =
            version
            |> Map.put(:original, empty_map_to_nil(new_struct))
            |> Map.put(:first, false)

          {version, old_struct}
        end)

      {versions, oldest_id} =
        versions
        |> Enum.map_reduce(nil, fn version, id ->
          {%{version | id: id}, version.id}
        end)

      versions ++
        [
          struct(version_schema(module), %{
            id: oldest_id
          })
          |> Map.put(:original, empty_map_to_nil(oldest_struct))
        ]
    else
      versions
    end
  end

  def history_query(module, %{id: id, __struct__: struct}) do
    from(
      v in version_schema(module),
      where: v.entity_id == ^id,
      where: v.entity_schema == ^struct,
      order_by: [desc: :recorded_at]
    )
  end

  @drop_fields [:__meta__, :__struct__]

  def revert(module, version, opts) do
    import Ecto.Query

    # get the history of the entity after this version

    query =
      from(
        v in version_schema(module),
        where: v.entity_id == ^version.entity_id,
        where: v.entity_schema == ^version.entity_schema,
        where: v.recorded_at >= ^version.recorded_at,
        order_by: [desc: :recorded_at]
      )

    versions = module.all(query)

    # get the referenced struct as it exists now

    struct = module.one(from(s in version.entity_schema, where: s.id == ^version.entity_id))

    result = Enum.reduce(versions, struct, &_revert/2)

    result = empty_map_to_nil(result)

    schema = version.entity_schema

    drop_from_params = @drop_fields ++ schema.__schema__(:associations)

    {action, changeset} =
      case {struct, result} do
        {nil, %{}} ->
          {:insert, schema.changeset(struct(schema, %{}), Map.drop(result, drop_from_params))}

        {%{}, nil} ->
          {:delete, struct}

        {nil, nil} ->
          {nil, nil}

        _ ->
          struct =
            case Keyword.get(opts, :preload) do
              nil -> struct
              [] -> struct
              preloads when is_list(preloads) -> module.preload(struct, preloads)
            end

          {:update, schema.changeset(struct, Map.drop(result, drop_from_params))}
      end

    opts =
      Keyword.update(opts, :ex_audit_custom, [rollback: true], fn custom ->
        [{:rollback, true} | custom]
      end)

    if action do
      res = apply(module, action, [changeset, opts])

      case action do
        :delete -> {:ok, nil}
        _ -> res
      end
    else
      Logger.warning([
        "Can't revert ",
        inspect(version),
        " because the entity would still be deleted"
      ])

      {:ok, nil}
    end
  end

  defp empty_map_to_nil(map) do
    if map |> Map.keys() |> length() == 0 do
      nil
    else
      map
    end
  end

  defp _revert(version, struct) do
    apply_change(reverse_action(version.action), ExAudit.Diff.reverse(version.patch), struct)
  end

  defp apply_change(:updated, patch, to) do
    ExAudit.Patch.patch(to, patch)
  end

  defp apply_change(:deleted, _patch, _to) do
    %{}
  end

  defp apply_change(:created, patch, _to) do
    ExAudit.Patch.patch(%{}, patch)
  end

  defp reverse_action(:updated), do: :updated
  defp reverse_action(:created), do: :deleted
  defp reverse_action(:deleted), do: :created

  defp version_schema(repo_module) do
    Application.get_env(:ex_audit, :ecto_repos_schemas) |> get_in([repo_module, :version_schema])
  end
end
