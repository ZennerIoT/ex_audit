defmodule ExAudit do
  use Application

  @tracked_schemas Application.compile_env(:ex_audit, :tracked_schemas)
  @spec tracked_schemas :: list(module())
  def tracked_schemas, do: @tracked_schemas

  @version_schema Application.compile_env(:ex_audit, :version_schema)
  @spec version_schema :: module()
  def version_schema, do: @version_schema

  @primitive_structs Application.compile_env(:ex_audit, :primitive_structs)
  @spec primitive_structs :: list(module())
  def primitive_structs, do: @primitive_structs

  @ignored_fields Application.compile_env(:ex_audit, :ignored_fields, [])
  @spec ignored_fields :: list(atom())
  def ignored_fields, do: @ignored_fields + [:__meta__, :__struct__]

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
  @spec tracked?(any) :: boolean
  def tracked?(%Ecto.Changeset{data: %{__struct__: struct}}), do: tracked?(struct)
  def tracked?(%{__struct__: struct}), do: tracked?(struct)
  def tracked?(struct) when struct in @tracked_schemas, do: true
  def tracked?(_), do: false
  defoverridable(tracked?: 1)

  def start(_, _) do
    import Supervisor.Spec

    children = [
      worker(ExAudit.CustomData, [])
    ]

    opts = [strategy: :one_for_one, name: ExAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Tracks the given keyword list of data for the current process
  """
  def track(data) do
    track_pid(self(), data)
  end

  @doc """
  Tracks the given keyword list of data for the given process
  """
  def track_pid(pid, data) do
    ExAudit.CustomData.track(pid, data)
  end
end
