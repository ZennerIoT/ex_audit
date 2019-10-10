import Config

config :ex_audit, ExAudit.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  username: "postgres",
  password: "postgres",
  database: "ex_audit_test",
  hostname: "localhost",
  pool_size: 10

config :logger, level: :info

config :ex_audit,
  ecto_repos: %{
    ExAudit.Test.Repo => %{
      version_schema: ExAudit.Test.Version,
      tracked_schemas: [
        ExAudit.Test.User,
        ExAudit.Test.BlogPost,
        ExAudit.Test.BlogPost.Section,
        ExAudit.Test.Comment
      ]
    }
  },
  primitive_structs: [
    Date
  ]
