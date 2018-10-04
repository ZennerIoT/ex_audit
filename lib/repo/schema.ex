defmodule ExAudit.Schema do
  def insert_all(module, adapter, schema_or_source, entries, opts) do
    # TODO!
    opts = augment_opts(opts)
    Ecto.Repo.Schema.insert_all(module, adapter, schema_or_source, entries, opts)
  end

  def insert(module, adapter, struct, opts) do
    if not Keyword.get(opts, :ignore_audit, false) do
      opts = augment_opts(opts)
      augment_transaction(module, fn ->
        result = Ecto.Repo.Schema.insert(module, adapter, struct, opts)

        case result do
          {:ok, resulting_struct} ->
            ExAudit.Tracking.track_change(module, adapter, :created, struct, resulting_struct, opts)
          _ ->
            :ok
        end

        result
      end)
    else
      Ecto.Repo.Schema.update(module, adapter, struct, opts)
    end
  end

  def update(module, adapter, struct, opts) do
    if not Keyword.get(opts, :ignore_audit, false) do
      opts = augment_opts(opts)
      augment_transaction(module, fn ->
        result = Ecto.Repo.Schema.update(module, adapter, struct, opts)

        case result do
          {:ok, resulting_struct} ->
            ExAudit.Tracking.track_change(module, adapter, :updated, struct, resulting_struct, opts)
          _ ->
            :ok
        end

        result
      end)
    else
      Ecto.Repo.Schema.update(module, adapter, struct, opts)
    end
  end

  def insert_or_update(module, adapter, changeset, opts) do
    # TODO!
    opts = augment_opts(opts)
    Ecto.Repo.Schema.insert_or_update(module, adapter, changeset, opts)
  end

  def delete(module, adapter, struct, opts) do
    opts = augment_opts(opts)
    augment_transaction(module, fn ->
      ExAudit.Tracking.track_assoc_deletion(module, adapter, struct, opts)
      result = Ecto.Repo.Schema.delete(module, adapter, struct, opts)

      case result do
        {:ok, resulting_struct} ->
          ExAudit.Tracking.track_change(module, adapter, :deleted, struct, resulting_struct, opts)
        _ ->
          :ok
      end

      result
    end)
  end

  def insert!(module, adapter, struct, opts) do
    opts = augment_opts(opts)
    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.insert!(module, adapter, struct, opts)
      ExAudit.Tracking.track_change(module, adapter, :created, struct, result, opts)
      result
    end, true)
  end

  def update!(module, adapter, struct, opts) do
    opts = augment_opts(opts)
    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.update!(module, adapter, struct, opts)
      ExAudit.Tracking.track_change(module, adapter, :updated, struct, result, opts)
      result
    end, true)
  end

  def insert_or_update!(module, adapter, changeset, opts) do
    # TODO
    opts = augment_opts(opts)
    Ecto.Repo.Schema.insert_or_update!(module, adapter, changeset, opts)
  end

  def delete!(module, adapter, struct, opts) do
    opts = augment_opts(opts)
    augment_transaction(module, fn ->
      ExAudit.Tracking.track_assoc_deletion(module, adapter, struct, opts)
      result = Ecto.Repo.Schema.delete!(module, adapter, struct, opts)
      ExAudit.Tracking.track_change(module, adapter, :deleted, struct, result, opts)
      result
    end, true)
  end

  # Cleans up the return value from repo.transaction
  defp augment_transaction(repo, fun, bang \\ false) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:main, __MODULE__, :run_in_multi, [fun, bang])

    case {repo.transaction(multi), bang} do
      {{:ok, %{main: value}}, false} -> {:ok, value}
      {{:ok, %{main: value}}, true} -> value
      {{:error, :main, error, _}, false} -> {:error, error}
      {{:error, :main, error, _}, true} -> raise error
    end
  end

  def run_in_multi(multi, fun, bang) do
    case {fun.(), bang} do
      {{:ok, _} = ok, false} -> ok
      {{:error, _} = error, false} -> error
      {value, true} -> {:ok, value}
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
