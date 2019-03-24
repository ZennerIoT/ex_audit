defmodule ExAudit.Test.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    belongs_to :author, ExAudit.Test.User
    field :body, :string

    belongs_to :blog_post, ExAudit.Test.BlogPost

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:author_id, :body])
  end
end
