defmodule JPMarc.ControlField do
  @typedoc """
      Type that represents `JPMarc.ControlField` struct

      This is constructed with `:tag` as binary and `:value` as binary.
  """
  @type t :: %JPMarc.ControlField{tag: binary, value: binary}
  defstruct tag: "", value: ""

  @doc """
    Return the MARC Format of the control field
  """
  def to_marc(field) do
     field.value <> "\x1e"
  end

end
