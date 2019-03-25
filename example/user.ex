defmodule ExAudit.Test.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {ExAudit.Tracker, except: [:transient_field]}

  schema "users" do
    field :email, :string
    field :name, :string

    field :transient_field, :integer

    has_many :groups, ExAudit.Test.UserGroup

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name])
  end
end
