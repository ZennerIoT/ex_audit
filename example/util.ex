defmodule ExAudit.Test.Util do
  alias ExAudit.Test.{Repo, User}

  def create_user(name \\ "Admin", email \\ "admin@example.com") do
    params = %{name: name, email: email}
    changeset = User.changeset(%User{}, params)
    Repo.insert!(changeset)
  end
end
