defmodule ExAudit.Repo do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour ExAudit.Repo

      {otp_app, adapter, config} = Ecto.Repo.Supervisor.compile_config(__MODULE__, opts)

      @otp_app otp_app
      @adapter adapter
      @config config

      def insert_all(schema_or_source, entries, opts \\ []) do
        ExAudit.Schema.insert_all(__MODULE__, @adapter, schema_or_source, entries, opts)
      end

      def update_all(queryable, updates, opts \\ []) do
        ExAudit.Queryable.update_all(__MODULE__, @adapter, queryable, updates, opts)
      end

      def delete_all(queryable, opts \\ []) do
        ExAudit.Queryable.delete_all(__MODULE__, @adapter, queryable, opts)
      end

      def insert(struct, opts \\ []) do
        ExAudit.Schema.insert(__MODULE__, @adapter, struct, opts)
      end

      def update(struct, opts \\ []) do
        ExAudit.Schema.update(__MODULE__, @adapter, struct, opts)
      end

      def insert_or_update(changeset, opts \\ []) do
        ExAudit.Schema.insert_or_update(__MODULE__, @adapter, changeset, opts)
      end

      def delete(struct, opts \\ []) do
        ExAudit.Schema.delete(__MODULE__, @adapter, struct, opts)
      end

      def insert!(struct, opts \\ []) do
        ExAudit.Schema.insert!(__MODULE__, @adapter, struct, opts)
      end

      def update!(struct, opts \\ []) do
        ExAudit.Schema.update!(__MODULE__, @adapter, struct, opts)
      end

      def insert_or_update!(changeset, opts \\ []) do
        ExAudit.Schema.insert_or_update!(__MODULE__, @adapter, changeset, opts)
      end

      def delete!(struct, opts \\ []) do
        ExAudit.Schema.delete!(__MODULE__, @adapter, struct, opts)
      end

      def history(queryable, id, opts \\ []) do
        # TODO update opts with the schema of the version table

        ExAudit.Queryable.history(__MODULE__, @adapter, queryable, id, opts)
      end

      def init(config), do: {:ok, config}

      defoverridable [init: 1, child_spec: 1]
    end
  end

  @callback init(config :: term) :: {:ok, config :: term}
end