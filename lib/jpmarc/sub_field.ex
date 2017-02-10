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

  defimpl Inspect, for: JPMarc.SubField do
    def inspect(%JPMarc.SubField{code: code, value: value}, _opts) do
      "$#{code} #{value}"
    end
  end

  defimpl String.Chars, for: JPMarc.SubField do
    def to_string(%JPMarc.SubField{code: code, value: value}) do
      "$#{code} #{value}"
    end
  end

end
