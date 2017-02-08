defmodule JPMarc.DataField do
  @typedoc """
      Type that represents `JPMarc.DataField` struct.

      This is constructed with `:tag` as binary, `:ind1` as binary, `:ind2` as binary and `:subfields` as List of `JPMarc.SubField.t`
  """
  @type t :: %JPMarc.DataField{tag: binary, ind1: binary, ind2: binary, subfields: [JPMarc.SubField.t]}
  defstruct tag: "", ind1: " ", ind2: " ", subfields: []

  @doc """
    Return the MARC Format of the data field
  """
  def to_marc(field) do
    sfs = field.subfields
      |> Enum.map(&JPMarc.SubField.to_marc/1)
      |> Enum.join

    field.ind1 <> field.ind2 <> sfs <> "\x1e"
  end

end
