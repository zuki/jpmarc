defmodule JPMarc.SubField do
  @typedoc """
      Type that represents `JPMarc.SubField` struct

      This is constructed with `:code` as binary and `:value` as binary.
  """
  @type t :: %JPMarc.SubField{code: binary, value: binary}
  defstruct code: "", value: ""

  @doc """
    Return the MARC Format of the subfield
  """
  def to_marc(field) do
    "\x1f" <> field.code <> field.value
  end

end
