defmodule ExAudit.Schema do
  def insert_all(module, adapter, schema_or_source, entries, opts) do
    # TODO!
    opts = augment_opts(opts)
    Ecto.Repo.Schema.insert_all(module, adapter, schema_or_source, entries, opts)
  end

  def insert(module, adapter, struct, opts) do
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
  end

  def update(module, adapter, struct, opts) do
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
  end

  def insert_or_update(module, adapter, changeset, opts) do
    # TODO!
    opts = augment_opts(opts)
    Ecto.Repo.Schema.insert_or_update(module, adapter, changeset, opts)
  end

  def delete(module, adapter, struct, opts) do
    opts = augment_opts(opts)
    augment_transaction(module, fn ->
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
    end)
  end

  def update!(module, adapter, struct, opts) do
    opts = augment_opts(opts)
    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.update!(module, adapter, struct, opts)
      ExAudit.Tracking.track_change(module, adapter, :updated, struct, result, opts)
      result
    end)
  end

  def insert_or_update!(module, adapter, changeset, opts) do
    # TODO
    opts = augment_opts(opts)
    Ecto.Repo.Schema.insert_or_update!(module, adapter, changeset, opts)
  end

  def delete!(module, adapter, struct, opts) do
    opts = augment_opts(opts)
    augment_transaction(module, fn ->
      result = Ecto.Repo.Schema.delete!(module, adapter, struct, opts)
      ExAudit.Tracking.track_change(module, adapter, :deleted, struct, result, opts)
      result
    end)
  end

  defp augment_transaction(repo, fun) do
    case repo.in_transaction?() do
      true -> fun.()
      false ->
        case repo.transaction(fun) do
          {:ok, value} -> value
          other -> other
        end
    end
  end

  defp augment_opts(opts) do
    opts
    |> Keyword.put_new(:ex_audit_custom, [])
    |> Keyword.update(:ex_audit_custom, [], fn custom_fields ->
      ExAudit.CustomData.get() ++ custom_fields
    end)
  end
end