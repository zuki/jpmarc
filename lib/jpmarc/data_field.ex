defmodule JPMarc.DataField do
  @typedoc """
      Type that represents `JPMarc.DataField` struct.

      This is constructed with `:tag` as binary, `:ind1` as binary, `:ind2` as binary and `:subfields` as List of `JPMarc.SubField.t`
  """
  @type t :: %JPMarc.DataField{tag: binary, ind1: binary, ind2: binary, subfields: [JPMarc.SubField.t]}
  defstruct tag: "", ind1: " ", ind2: " ", subfields: []
end
