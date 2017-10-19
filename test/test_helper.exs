:ok = Application.ensure_started(:ex_audit)
ExAudit.Test.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(ExAudit.Test.Repo, :auto)

ExUnit.start()
