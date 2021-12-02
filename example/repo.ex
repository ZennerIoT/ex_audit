defmodule ExAudit.Test.Repo do
  use Ecto.Repo,
    otp_app: :ex_audit,
    adapter: Ecto.Adapters.Postgres

  use ExAudit.Repo

  def custom_history_fetch_latest_version_only(struct, opts \\ []) do
    ExAudit.Queryable.history(__MODULE__, struct, fn module, query, opts ->
      import Ecto.Query

      Ecto.Repo.Queryable.one(module, limit(query, 1), opts)
    end, opts)
  end
end
