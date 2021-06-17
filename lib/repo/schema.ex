defmodule ExAudit.Schema do
  def insert_all(module, name, schema, entries, opts) do
    updated_opts =
      opts
      |> augment_opts()
      |> Keyword.put(:returning, true)

    {:ok, result} =
      augment_transaction(module, fn ->
        module
        |> do_insert_all(name, schema, entries, updated_opts)
        |> maybe_track_changes(module, :created, schema, updated_opts)
      end)

    opts
    |> Keyword.get(:returning)
    |> format_result(result)
  end

  defp do_insert_all(module, name, schema, entries, opts) do
    Ecto.Repo.Schema.insert_all(
      module,
      name,
      schema,
      entries,
      opts
    )
  end

  defp maybe_track_changes(
         {_number_of_entries, nil} = insert_all_result,
         _module,
         _action,
         _schema,
         _opts
       ) do
    insert_all_result
  end

  defp maybe_track_changes(
         {_number_of_entries, returns} = insert_all_result,
         module,
         action,
         schema,
         opts
       ) do
    Enum.each(
      returns,
      &ExAudit.Tracking.track_change(module, action, schema, &1, opts)
    )

    insert_all_result
  end

  defp format_result(fields, {number_of_entries, returns}) when is_list(fields) do
    updated_returns =
      Enum.reduce(returns, [], fn return, acc ->
        [filter_struct_fields(fields, return) | acc]
      end)

    {number_of_entries, updated_returns}
  end

  defp format_result(true, result), do: result
  defp format_result(_, {number_of_entries, _returns}), do: {number_of_entries, nil}

  defp filter_struct_fields(fields, struct) do
    struct
    |> Map.from_struct()
    |> Enum.reduce(struct.__struct__.__struct__(), fn {key, value}, acc ->
      if key in fields, do: Map.put(acc, key, value), else: acc
    end)
  end

  def insert(module, name, struct, opts) do
    opts = augment_opts(opts)

    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.insert(module, name, struct, opts)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(module, :created, struct, resulting_struct, opts)

        _ ->
          :ok
      end

      result
    end)
  end

  def update(module, name, struct, opts) do
    opts = augment_opts(opts)

    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.update(module, name, struct, opts)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(module, :updated, struct, resulting_struct, opts)

        _ ->
          :ok
      end

      result
    end)
  end

  def insert_or_update(module, name, changeset, opts) do
    opts = augment_opts(opts)

    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.insert_or_update(module, name, changeset, opts)

      case result do
        {:ok, resulting_struct} ->
          state = if changeset.data.__meta__.state == :loaded, do: :updated, else: :created
          ExAudit.Tracking.track_change(module, state, changeset, resulting_struct, opts)

        _ ->
          :ok
      end

      result
    end)
  end

  def delete(module, name, struct, opts) do
    opts = augment_opts(opts)

    augment_transaction(module, fn ->
      ExAudit.Tracking.track_assoc_deletion(module, struct, opts)
      result = Ecto.Repo.Schema.delete(module, name, struct, opts)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(module, :deleted, struct, resulting_struct, opts)

        _ ->
          :ok
      end

      result
    end)
  end

  def insert!(module, name, struct, opts) do
    opts = augment_opts(opts)

    augment_transaction(
      module,
      fn ->
        result = Ecto.Repo.Schema.insert!(module, name, struct, opts)
        ExAudit.Tracking.track_change(module, :created, struct, result, opts)
        result
      end,
      true
    )
  end

  def update!(module, name, struct, opts) do
    opts = augment_opts(opts)

    augment_transaction(
      module,
      fn ->
        result = Ecto.Repo.Schema.update!(module, name, struct, opts)
        ExAudit.Tracking.track_change(module, :updated, struct, result, opts)
        result
      end,
      true
    )
  end

  def insert_or_update!(module, name, changeset, opts) do
    opts = augment_opts(opts)

    augment_transaction(
      module,
      fn ->
        result = Ecto.Repo.Schema.insert_or_update!(module, name, changeset, opts)
        state = if changeset.data.__meta__.state == :loaded, do: :updated, else: :created
        ExAudit.Tracking.track_change(module, state, changeset, result, opts)
        result
      end,
      true
    )
  end

  def delete!(module, name, struct, opts) do
    opts = augment_opts(opts)

    augment_transaction(
      module,
      fn ->
        ExAudit.Tracking.track_assoc_deletion(module, struct, opts)
        result = Ecto.Repo.Schema.delete!(module, name, struct, opts)
        ExAudit.Tracking.track_change(module, :deleted, struct, result, opts)
        result
      end,
      true
    )
  end

  # Cleans up the return value from repo.transaction
  defp augment_transaction(repo, fun, bang \\ false) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:main, __MODULE__, :run_in_multi, [fun, bang])

    case {repo.transaction(multi), bang} do
      {{:ok, %{main: value}}, false} ->
        {:ok, value}

      {{:ok, %{main: value}}, true} ->
        value

      {{:error, :main, error, _}, false} ->
        {:error, error}

      {{:error, :main, error, _}, true} ->
        raise error

      {{entries, return}, false} ->
        {entries, return}
    end
  end

  def run_in_multi(_repo, _multi, fun, bang) do
    case {fun.(), bang} do
      {{:ok, _} = ok, false} -> ok
      {{:error, _} = error, false} -> error
      {value, true} -> {:ok, value}
      {{entries, return}, _} -> {:ok, {entries, return}}
    end
  end

  # Gets the custom data from the ets store that stores it by PID, and adds
  # it to the list of custom data from the options list
  #
  # This is done so it works inside a transaction (which happens when ecto mutates assocs at the same time)

  defp augment_opts(opts) do
    opts
    |> Keyword.put_new(:ex_audit_custom, [])
    |> Keyword.update(:ex_audit_custom, [], fn custom_fields ->
      case Process.whereis(ExAudit.CustomData) do
        nil -> []
        _ -> ExAudit.CustomData.get()
      end ++ custom_fields
    end)
  end
end
