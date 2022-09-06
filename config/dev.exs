import Config

config :ex_audit,
  ecto_repos: [ExAudit.Test.Repo],
  version_schema: ExAudit.Test.Version,
  tracked_schemas: [
    ExAudit.Test.User,
    ExAudit.Test.BlogPost,
    ExAudit.Test.BlogPost.Section,
    ExAudit.Test.Comment
  ],
  primitive_structs: [
    Date
  ]
