defmodule ExAudit.Test.Repo.Migrations.NoCascadeDelete do
  use Ecto.Migration

  def change do
    create table(:user_groups) do
      add :name, :string
      add :user_id, references(:users)
    end
  end
end
