# ExAudit

Ecto auditing library that transparently tracks changes and can revert them.

ExAudit plugs right into your ecto repositories and hooks all the data mutating Ecto.Repo functions
to track changes to entities in your database.

## Setup

You have to hook ExAudit to your repo, by adding

`use ExAudit.Repo, otp_app: :my_app` here:

```elixir
defmodule MyApp.Repo
  use ExAudit.Repo, otp_app: :my_app # <- before Ecto.Repo
  use Ecto.Repo, otp_app: :my_app
end
```

Create a schema module and migration for the versions table. This table will automatically be ignored:

### Schema

```elixir
defmodule MyApp.Version
  use Ecto.Schema
  import Ecto.Changeset

  schema "versions" do
    field :patch, ExAudit.Type.Patch
    field :entity_id, :integer
    field :entity_schema, :string
    field :action, ExAudit.Type.Action
    field :recorded_at, :utc_datetime

    # custom fields
    has_one :actor, MyApp.User
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:patch, :entity_id, :entity_schema, :action, :recorded_at])
    |> cast(params, [:actor_id]) # custom fields
  end
end
```

### Migration

```elixir
defmodule MyApp.Migrations.AddVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      # The patch in Erlang External Term Format
      add :patch, :binary

      # supports UUID and other types as well
      add :entity_id, :integer 

      # name of the table the entity is in
      add :entity_schema, :string 

      # type of the action that has happened to the entity (created, updated, deleted)
      add :action, :string

      # when has this happened
      add :recorded_at, :utc_datetime

      # optional fields that you can define yourself
      # for example, it's a good idea to track who did the change
      add :actor_id, references(:users, on_update: :update_all, :on_delete: :nilify_all)
    end
  end
end
```

### Recording custom data

If you want to track custom data such as the user id, you can simply pass a keyword list with that data
to the `:ex_audit_custom` option in any Repo function:

```elixir
MyApp.Repo.insert(changeset, ex_audit_custom: [user_id: conn.assigns.current_user.id])
```

Of course it is tedious to upgrade your entire codebase just to track the user ID for example, so you can 
also pass this data in a plug:

```elixir
defmodule MyApp.ExAuditPlug do
  def init(_) do
    nil
  end

  def call(conn, _) do
    ExAudit.track(user_id: conn.assigns.current_user.id)
    conn
  end
end
```

In the background, ExAudit.track will remember the PID it was called from and attaches the passed data to that 
PID. In most cases, the conn process will call the Repo functions, so ExAudit can get the data from that PID again deeper
in the plug tree.

In some cases where it is not possible to call the Repo function from the conn process, you have to pass the 
custom data manually via the options described above.

## Installation

ExAudit can be installed by adding `ex_audit` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_audit, "~> 0.1.0"}
  ]
end
```

The documentation is at [https://hexdocs.pm/ex_audit](https://hexdocs.pm/ex_audit).
