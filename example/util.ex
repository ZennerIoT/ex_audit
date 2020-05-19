defmodule ExAudit.Test.Util do
  alias ExAudit.Test.{Repo, User}

  def create_user(name \\ "Admin", email \\ "admin@example.com", worth \\ Decimal.new("100")) do
    params = %{name: name, email: email, worth: worth}
    changeset = User.changeset(%User{}, params)
    Repo.insert!(changeset)
  end
end
