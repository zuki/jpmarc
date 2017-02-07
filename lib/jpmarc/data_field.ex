defmodule JPMarc.DataField do
  @typedoc """
      Type that represents JPMarc.DataField struct with :tag as binary, :indicator as binary
      and :subfields as List of JPMarc.SubField.t
  """
  @type t :: %JPMarc.DataField{tag: binary, indicator: binary, subfields: [JPMarc.SubField.t]}
  defstruct tag: "", indicator: "  ", subfields: []
end
