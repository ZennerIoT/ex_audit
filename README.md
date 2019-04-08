# ExAudit

Ecto auditing library that transparently tracks changes and can revert them.

ExAudit plugs right into your ecto repositories and hooks all the data mutating Ecto.Repo functions
to track changes to entities in your database.

## Features
 
 * Wraps Ecto.Repo, no need to change your existing codebase to start tracking changes
 * Creates +- diffs of the casted structs. Custom types are automatically supported.
 * Ships with functions to review the history of a struct and roll back changes
 * Allows custom ID types and custom fields in the version schema
 * Tracks associated entities when they're created, updated or deleted in a single Repo call
 * Recursively tracks cascading deletions

## Usage

ExAudit replaces some functions in your repo module:

 * `insert/2`
 * `insert!/2`
 * `update/2`
 * `update!/2`
 * `delete/2`
 * `delete!/2`

All changes to the database made with these functions will automatically be tracked.

Also, new functions are added to the repository:

 * `history/2`: lists all versions of the given struct ordered from oldest to newest
 * `revert/2`: rolls the referenced entity back to the state it was before the given version
   was changed

With this API, you should be able to enable auditing across your entire application easily.

If for some reason ExAudit does not track a change, you can manually add it with 
`ExAudit.Tracking.track_change(module, adapter, action, changeset, resulting_struct, opts)`.

In the same module, there are a few other functions you might find useful to roll custom
tracking.

## Setup

Add ex_audit to your list of dependencies:

```elixir
def deps do
  [
    {:ex_audit, "~> 0.6"}
  ]
end
```

You have to hook ExAudit to your repo, by replacing `Ecto.Repo` with `ExAudit.Repo`:

```elixir
defmodule MyApp.Repo do
  use ExAudit.Repo, otp_app: :my_app
end
```

### Configuration

You have to tell ExAudit which schemas to track and the module of your version schema.

In your config.exs, write something like this:

```elixir
config :ex_audit, 
  version_schema: MyApp.Version, 
  tracked_schemas: [
    MyApp.User,
    MyApp.BlogPost,
    MyApp.Comment
  ]
```

### Version Schema and Migration

You need to copy the migration and the schema module for the versions table. This allows you to add custom fields
to the table or decide which type to use for the primary key.

#### `version.ex`

```elixir
defmodule MyApp.Version do
  use Ecto.Schema
  import Ecto.Changeset

  schema "versions" do
    # The patch in Erlang External Term Format
    field :patch, ExAudit.Type.Patch

    # supports UUID and other types as well
    field :entity_id, :integer

    # name of the table the entity is in
    field :entity_schema, ExAudit.Type.Schema

    # type of the action that has happened to the entity (created, updated, deleted)
    field :action, ExAudit.Type.Action

    # when has this happened
    field :recorded_at, :utc_datetime

    # was this change part of a rollback?
    field :rollback, :boolean, default: false

    # custom fields
    belongs_to :actor, MyApp.User
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:patch, :entity_id, :entity_schema, :action, :recorded_at, :rollback])
    |> cast(params, [:actor_id]) # custom fields
  end
end
```

#### `create_version_table.exs`

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

      # was this change part of a rollback?
      add :rollback, :boolean, default: false

      # optional fields that you can define yourself
      # for example, it's a good idea to track who did the change
      add :actor_id, references(:users, on_update: :update_all, on_delete: :nilify_all)
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

Examples for data you might want to track additionally:

 * User ID
 * API Key ID 
 * Message from the user describing what she changed

## Ecto versions

If you're using ecto 2.x, use `{:ex_audit, "~> 0.5"}`

If you're using ecto 3.0, upgrade ecto to 3.1

If you're using ecto 3.1, use `{:ex_audit, "~> 0.6"}`

## More

The documentation is available at [https://hexdocs.pm/ex_audit](https://hexdocs.pm/ex_audit).

Check out [ZENNER IoT Solutions](https://zenner-iot.com/), makers of the [ELEMENT IoT platform](https://zenner-iot.com/iot-plattform).