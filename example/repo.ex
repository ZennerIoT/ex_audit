defmodule ExAudit.Test.Repo do
  use ExAudit.Repo, otp_app: :ex_audit, adapter: Ecto.Adapters.Postgres
end
