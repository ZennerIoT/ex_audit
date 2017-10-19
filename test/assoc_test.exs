defmodule AssocTest do
  use ExUnit.Case

  import Ecto.Query

  alias ExAudit.Test.{Repo, User, Version, BlogPost, Comment, Util}

  test "comment lifecycle tracked" do
    user = Util.create_user()

    params = %{
      title: "Controversial post",
      author_id: user.id,
      comments: [
        %{
          body: "lorem impusdrfnia",
          author_id: user.id
        }
      ]
    }

    changeset = BlogPost.changeset(%BlogPost{}, params)
    {:ok, %{comments: [comment]} = blog_post} = Repo.insert(changeset)

    comment_history = Repo.history(comment)
    assert length(comment_history) == 1
  end
end