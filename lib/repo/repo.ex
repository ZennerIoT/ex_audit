defmodule ExAudit.Repo do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Ecto.Repo

      {otp_app, adapter, config} = Ecto.Repo.Supervisor.compile_config(__MODULE__, opts)
      @otp_app otp_app
      @adapter adapter
      @config  config
      @before_compile adapter

      loggers =
        Enum.reduce(opts[:loggers] || config[:loggers] || [Ecto.LogEntry], quote(do: entry), fn
          mod, acc when is_atom(mod) ->
            quote do: unquote(mod).log(unquote(acc))
          {Ecto.LogEntry, :log, [level]}, _acc when not level in [:error, :info, :warn, :debug] ->
            raise ArgumentError, "the log level #{inspect level} is not supported in Ecto.LogEntry"
          {mod, fun, args}, acc ->
            quote do: unquote(mod).unquote(fun)(unquote(acc), unquote_splicing(args))
        end)

      def __adapter__ do
        @adapter
      end

      def __log__(entry) do
        unquote(loggers)
      end

      def config do
        {:ok, config} = Ecto.Repo.Supervisor.runtime_config(:dry_run, __MODULE__, @otp_app, [])
        config
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        Ecto.Repo.Supervisor.start_link(__MODULE__, @otp_app, @adapter, opts)
      end

      def stop(pid, timeout \\ 5000) do
        Supervisor.stop(pid, :normal, timeout)
      end

      if function_exported?(@adapter, :transaction, 3) do
        def transaction(fun_or_multi, opts \\ []) do
          Ecto.Repo.Queryable.transaction(@adapter, __MODULE__, fun_or_multi, opts)
        end

        def in_transaction? do
          @adapter.in_transaction?(__MODULE__)
        end

        @spec rollback(term) :: no_return
        def rollback(value) do
          @adapter.rollback(__MODULE__, value)
        end
      end

      def all(queryable, opts \\ []) do
        Ecto.Repo.Queryable.all(__MODULE__, @adapter, queryable, opts)
      end

      def stream(queryable, opts \\ []) do
        Ecto.Repo.Queryable.stream(__MODULE__, @adapter, queryable, opts)
      end

      def get(queryable, id, opts \\ []) do
        Ecto.Repo.Queryable.get(__MODULE__, @adapter, queryable, id, opts)
      end

      def get!(queryable, id, opts \\ []) do
        Ecto.Repo.Queryable.get!(__MODULE__, @adapter, queryable, id, opts)
      end

      def get_by(queryable, clauses, opts \\ []) do
        Ecto.Repo.Queryable.get_by(__MODULE__, @adapter, queryable, clauses, opts)
      end

      def get_by!(queryable, clauses, opts \\ []) do
        Ecto.Repo.Queryable.get_by!(__MODULE__, @adapter, queryable, clauses, opts)
      end

      def one(queryable, opts \\ []) do
        Ecto.Repo.Queryable.one(__MODULE__, @adapter, queryable, opts)
      end

      def one!(queryable, opts \\ []) do
        Ecto.Repo.Queryable.one!(__MODULE__, @adapter, queryable, opts)
      end

      def aggregate(queryable, aggregate, field, opts \\ [])
          when aggregate in [:count, :avg, :max, :min, :sum] and is_atom(field) do
        Ecto.Repo.Queryable.aggregate(__MODULE__, @adapter, queryable, aggregate, field, opts)
      end

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

      def preload(struct_or_structs_or_nil, preloads, opts \\ []) do
        Ecto.Repo.Preloader.preload(struct_or_structs_or_nil, __MODULE__, preloads, opts)
      end

      def load(schema_or_types, data) do
        Ecto.Repo.Schema.load(@adapter, schema_or_types, data)
      end


      defoverridable [child_spec: 1]
    end
  end
end