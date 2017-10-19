defmodule ExAudit.Test.BlogPost do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blog_post" do
    field :title, :string

    belongs_to :author, ExAudit.Test.User
    embeds_many :sections, ExAudit.Test.BlogPost.Section

    has_many :comments, ExAudit.Test.Comment

    timestamps(type: :utc_datetime)
  end

  defmodule Section do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :title, :string
      field :text, :string
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:title, :text])
    end
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :author_id])
    |> cast_assoc(:comments)
    |> cast_embed(:sections)
  end
end