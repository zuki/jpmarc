defmodule JPMarc.DataField do
  alias JPMarc.Const
  alias JPMarc.SubField

  @typedoc """
      Type that represents `JPMarc.DataField` struct.

      This is constructed with `:tag` as String, `:ind1` as String, `:ind2` as String and `:subfields` as List of `JPMarc.SubField.t`
  """
  @type t :: %JPMarc.DataField{tag: String.t, ind1: String.t, ind2: String.t, subfields: [SubField.t]}
  defstruct tag: "", ind1: " ", ind2: " ", subfields: []

  @doc """
    Return the MARC Format of the data field
  """
  @spec to_marc(JPMarc.DataField.t)::String.t
  def to_marc(field) do
    subfields = field.subfields
      |> Enum.map(&SubField.to_marc/1)
      |> Enum.join

    field.ind1 <> field.ind2 <> subfields <> Const.fs
  end

end
