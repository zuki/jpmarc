defmodule JPMarc.SubField do
  # Subfield separator
  @ss "\x1f"


  @typedoc """
      Type that represents `JPMarc.SubField` struct

      This is constructed with `:code` as String and `:value` as String.
  """
  @type t :: %JPMarc.SubField{code: String.t, value: String.t}
  defstruct code: "", value: ""

  @doc """
    Return the MARC Format of the subfield
  """
  @spec to_marc(JPMarc.SubField.t)::String.t
  def to_marc(field) do
    @ss <> field.code <> field.value
  end

end
