defmodule ExAudit do
  use Application

  @tracked_schemas Application.compile_env(:ex_audit, :tracked_schemas)
  @spec tracked_schemas :: list(module())
  def tracked_schemas, do: @tracked_schemas

  @version_schema Application.compile_env(:ex_audit, :version_schema)
  @spec version_schema :: module()
  def version_schema, do: @version_schema

  @primitive_structs Application.compile_env(:ex_audit, :primitive_structs, [])
  @spec primitive_structs :: list(module())
  def primitive_structs, do: @primitive_structs

  @ignored_fields Application.compile_env(:ex_audit, :ignored_fields, [])
  @spec ignored_fields :: list(atom())
  def ignored_fields, do: @ignored_fields ++ [:__meta__, :__struct__]

  @doc """
    Indicates if a module should be tracked.

    Can be overwritten for custom tracking logic.
    E.g.
    ```
      def tracked?(struct_or_changeset) do
        %{force_tracking: force_tracking} = struct_or_changeset
        force_tracking && super(struct_or_changeset)
      end
    ```
  """
  @spec tracked?(any) :: boolean
  def tracked?(%Ecto.Changeset{data: %struct{}}), do: tracked?(struct)
  def tracked?(%struct{}), do: tracked?(struct)
  def tracked?(struct) when struct in @tracked_schemas, do: true
  def tracked?(_), do: false
  defoverridable(tracked?: 1)

  def start(_, _) do
    import Supervisor.Spec

    children = [
      worker(ExAudit.Tracker.AdditionalData, [])
    ]

    opts = [strategy: :one_for_one, name: ExAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
    Adds data to the current process as supplemental data for the
    audit log
  """
  def additional_data(data) do
    ExAudit.Tracking.AdditionalData.track(self(), data)
  end
end
