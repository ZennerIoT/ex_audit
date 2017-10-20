use Mix.Config

config :ex_audit, ExAudit.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ex_audit_test",
  hostname: "localhost",
  pool_size: 10


import_config "#{Mix.env}.exs"