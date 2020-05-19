:ok = Application.ensure_started(:ex_audit)
ExAudit.Test.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(ExAudit.Test.Repo, :auto)

migrations_path = Path.join([:code.priv_dir(:ex_audit), "repo", "migrations"])
Ecto.Migrator.run(ExAudit.Test.Repo, migrations_path, :up, all: true)

ExUnit.start()
