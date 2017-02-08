defmodule JPMarc.SubField do
  alias JPMarc.Const

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
    Const.ss <> field.code <> field.value
  end

end
