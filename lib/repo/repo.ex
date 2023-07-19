defmodule ExAudit.Repo do
  @moduledoc """
  Adds ExAudit version tracking to your Ecto.Repo actions. The following functions are
  extended to detect if the given struct or changeset is in the list of :tracked_schemas
  given in :ex_audit config:

    insert: 2,
    update: 2,
    insert_or_update: 2,
    delete: 2,
    insert!: 2,
    update!: 2,
    insert_or_update!: 2,
    delete!: 2

  If the given struct or changeset is not tracked then the original function from Ecto.Repo is
  executed, i.e., the functions are marked as overridable and the overrided implementations
  call `Kernel.super/1` when the given struct or changeset is not tracked.

  ## How to use it.

  Just `use ExAudit.Repo` after `Ecto.Repo`

    ```elixir
    defmodule MyApp.Repo do
      use Ecto.Repo,
        otp_app: :my_app,
        adapter: Ecto.Adapters.Postgres

      use ExAudit.Repo
    end
    ```

  ## Shared options

  All normal Ecto.Repo options will work the same, however, there are additional options specific to ex_audit:

   * `:ex_audit_custom` - Keyword list of custom data that should be placed in new version entries. Entries in this
     list overwrite data with the same keys from the ExAudit.track call
   * `:ignore_audit` - If true, ex_audit will not track changes made to entities
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour ExAudit.Repo

      # These are the Ecto.Repo functions that ExAudit "extends" but these are not
      # marked as overridable in Ecto.Repo. (ecto v3.4.2)
      defoverridable(
        insert: 2,
        update: 2,
        insert_or_update: 2,
        delete: 2,
        insert!: 2,
        update!: 2,
        insert_or_update!: 2,
        delete!: 2
      )

      @doc """
        Decides based on config `tracked_schema` wether the current schema is tracked or not.
        Can be overwritten for custom tracking logic.

        E.g.
        ```
          def tracked?(struct_or_schema) do
            tracked? =
              case Process.get(__MODULE__) do
                %{tracked?: true} -> true
                _ -> false
              end

            tracked? && super(struct_or_schema)
          end
        ```
      """
      @compile {:inline, tracked?: 2}

      defp tracked?(repo_module, struct_or_changeset) do
        tracked_schemas = ExAudit.Tracking.tracked_schemas(repo_module)

        schema =
          case struct_or_changeset do
            %Ecto.Changeset{} = changeset ->
              Map.get(changeset.data, :__struct__)

            _ ->
              Map.get(struct_or_changeset, :__struct__)
          end

        schema in tracked_schemas
      end

      defoverridable(tracked?: 2)

      def insert(struct, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, struct) do
          ExAudit.Schema.insert(
            __MODULE__,
            repo,
            struct,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:insert, opts))
          )
        else
          super(struct, opts)
        end
      end

      def update(struct, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, struct) do
          ExAudit.Schema.update(
            __MODULE__,
            repo,
            struct,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:update, opts))
          )
        else
          super(struct, opts)
        end
      end

      def insert_or_update(changeset, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, changeset) do
          ExAudit.Schema.insert_or_update(
            __MODULE__,
            repo,
            changeset,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:insert_or_update, opts))
          )
        else
          super(changeset, opts)
        end
      end

      def delete(struct, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, struct) do
          ExAudit.Schema.delete(
            __MODULE__,
            repo,
            struct,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:delete, opts))
          )
        else
          super(struct, opts)
        end
      end

      def insert!(struct, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, struct) do
          ExAudit.Schema.insert!(
            __MODULE__,
            repo,
            struct,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:insert, opts))
          )
        else
          super(struct, opts)
        end
      end

      def update!(struct, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, struct) do
          ExAudit.Schema.update!(
            __MODULE__,
            repo,
            struct,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:update, opts))
          )
        else
          super(struct, opts)
        end
      end

      def insert_or_update!(changeset, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, changeset) do
          ExAudit.Schema.insert_or_update!(
            __MODULE__,
            repo,
            changeset,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:insert_or_update, opts))
          )
        else
          super(changeset, opts)
        end
      end

      def delete!(struct, opts) do
        repo = get_dynamic_repo()

        if tracked?(__MODULE__, struct) do
          ExAudit.Schema.delete!(
            __MODULE__,
            repo,
            struct,
            Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:delete, opts))
          )
        else
          super(struct, opts)
        end
      end

      defoverridable(child_spec: 1)

      # additional functions

      def history(struct, opts \\ []) do
        ExAudit.Queryable.history(__MODULE__, struct, opts)
      end

      def revert(version, opts \\ []) do
        ExAudit.Queryable.revert(__MODULE__, version, opts)
      end

      def history_query(struct) do
        ExAudit.Queryable.history_query(__MODULE__, struct)
      end
    end
  end

  @doc """
  Gathers the version history for the given struct, ordered by the time the changes
  happened from newest to oldest.
  ### Options
   * `:render_struct` if true, renders the _resulting_ struct of the patch for every version in its history.
     This will shift the ids of the versions one down, so visualisations are correct and corresponding "Revert"
     buttons revert the struct back to the visualized state.
     Will append an additional version that contains the oldest ID and the oldest struct known. In most cases, the
     `original` will be `nil` which means if this version would be reverted, the struct would be deleted.
     `false` by default.
  """
  @callback history(struct, opts :: list) :: [version :: struct]

  @doc """
  Returns a query that gathers the version history for the given struct, ordered by the time the changes
  happened from newest to oldest.
  """
  @callback history_query(struct) :: Ecto.Query.t()

  @doc """
  Undoes the changes made in the given version, as well as all of the following versions.
  Inserts a new version entry in the process, with the `:rollback` flag set to true
  ### Options
   * `:preload` if your changeset depends on assocs being preloaded on the struct before
     updating it, you can define a list of assocs to be preloaded with this option
  """
  @callback revert(version :: struct, opts :: list) ::
              {:ok, struct} | {:error, changeset :: Ecto.Changeset.t()}
end
