defmodule AshHq.Repo.Migrations.MigrateResources6 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:extensions) do
      add :doc, :text, null: false
    end
  end

  def down do
    alter table(:extensions) do
      remove :doc
    end
  end
end