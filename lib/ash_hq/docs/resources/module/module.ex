defmodule AshHq.Docs.Module do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshHq.Docs.Extensions.Search, AshHq.Docs.Extensions.RenderMarkdown]

  postgres do
    table "modules"
    repo AshHq.Repo

    references do
      reference :library_version, on_delete: :delete
    end
  end

  actions do
    defaults [:update, :destroy]

    read :read do
      primary? true

      pagination offset?: true,
                 keyset?: true,
                 countable: true,
                 default_limit: 25,
                 required?: false
    end

    create :create do
      primary? true
      argument :functions, {:array, :map}
      argument :library_version, :uuid

      change {AshHq.Docs.Changes.AddArgToRelationship, arg: :library_version, rel: :functions}
      change manage_relationship(:functions, type: :direct_control)
      change manage_relationship(:library_version, type: :append_and_remove)
    end
  end

  search do
    doc_attribute :doc

    weight_content(0.5)

    load_for_search [
      :version_name,
      :library_name,
      :library_id
    ]

    type "Code"
  end

  render_markdown do
    render_attributes doc: :doc_html
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :category, :string do
      allow_nil? false
      default "Misc"
    end

    attribute :file, :string

    attribute :doc, :string do
      allow_nil? false
      constraints trim?: false, allow_empty?: true
      default ""
    end

    attribute :doc_html, :string do
      constraints trim?: false, allow_empty?: true
      writable? false
    end

    attribute :order, :integer do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :library_version, AshHq.Docs.LibraryVersion do
      allow_nil? true
    end

    has_many :functions, AshHq.Docs.Function
  end

  code_interface do
    define_for AshHq.Docs
  end

  resource do
    description "Represents a module that has been exposed by a library"
  end

  calculations do
    calculate :version_name, :string, expr(library_version.version)
    calculate :library_name, :string, expr(library_version.library.name)
    calculate :library_id, :uuid, expr(library_version.library.id)
  end
end
