defmodule AssocTest do
  use ExUnit.Case

  import Ecto.Query

  alias ExAudit.Test.{Repo, Version, BlogPost, Comment, Util, User, UserGroup}

  test "comment lifecycle tracked" do
    user = Util.create_user()

    ExAudit.track(actor_id: user.id)

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
    {:ok, %{comments: [comment]}} = Repo.insert(changeset)

    [%{actor_id: actor_id}] = comment_history = Repo.history(comment)
    assert length(comment_history) == 1
    assert actor_id == user.id
  end

  test "decimals are treated as primitives" do
    user = Util.create_user()
    old_worth = user.worth
    new_worth = Decimal.new("2000.00")

    changeset = User.changeset(user, %{worth: new_worth})
    {:ok, user} = Repo.update(changeset)

    [version | _] = Repo.history(user)

    assert %{
             patch: %{
               worth: {:changed, {:primitive_change, ^old_worth, ^new_worth}}
             }
           } = version
  end

  test "should track cascading deletions (before they happen)" do
    user = Util.create_user()

    ExAudit.track(actor_id: user.id)

    params = %{
      title: "Controversial post",
      author_id: user.id,
      comments: [
        %{
          body: "lorem impusdrfnia",
          author_id: user.id
        },
        %{
          body: "That's a nice article",
          author_id: user.id
        },
        %{
          body: "We want more of this CONTENT",
          author_id: user.id
        }
      ]
    }

    changeset = BlogPost.changeset(%BlogPost{}, params)
    {:ok, %{comments: comments} = blog_post} = Repo.insert(changeset)

    Repo.delete(blog_post)

    comment_ids = Enum.map(comments, & &1.id)

    versions =
      Repo.all(
        from(v in Version,
          where: v.entity_id in ^comment_ids,
          where: v.entity_schema == ^Comment
        )
      )

    # 3 created, 3 deleted
    assert length(versions) == 6
  end

  test "should return changesets from constraint errors" do
    user = Util.create_user()

    ch = UserGroup.changeset(%UserGroup{}, %{name: "a group", user_id: user.id})
    {:ok, _group} = Repo.insert(ch)

    import Ecto.Changeset

    deletion =
      user
      |> change
      |> no_assoc_constraint(:groups)

    assert {:error, %Ecto.Changeset{}} = Repo.delete(deletion)
  end
end
