defmodule ExAudit.Test.Repo do
  use Ecto.Repo,
    otp_app: :ex_audit,
    adapter: Ecto.Adapters.Postgres

  use ExAudit.Repo
end
