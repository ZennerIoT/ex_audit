defmodule ExAudit.Test.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blog_post" do
    has_one :author, Test.User
    field :body, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:author_id, :body])
  end
end