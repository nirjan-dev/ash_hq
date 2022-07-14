defmodule AshHq.Repo.Migrations.MigrateResources9 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:options) do
      add :argument_index, :bigint
    end

    alter table(:modules) do
      add :file, :text
    end

    alter table(:guides) do
      modify :category, :text, default: "Topics"
    end

    alter table(:functions) do
      add :file, :text
      add :line, :bigint
    end

    alter table(:dsls) do
      add :imports, {:array, :text}
      add :links, :map
    end
  end

  def down do
    alter table(:dsls) do
      remove :links
      remove :imports
    end

    alter table(:functions) do
      remove :line
      remove :file
    end

    alter table(:guides) do
      modify :category, :text, default: "Guides"
    end

    alter table(:modules) do
      remove :file
    end

    alter table(:options) do
      remove :argument_index
    end
  end
end