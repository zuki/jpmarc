defmodule JPMarc.ControlField do
  alias JPMarc.Const

  @typedoc """
      Type that represents `JPMarc.ControlField` struct

      This is constructed with `:tag` as String and `:value` as String.
  """
  @type t :: %JPMarc.ControlField{tag: String.t, value: String.t}
  defstruct tag: "", value: ""

  @doc """
    Return the MARC Format of the control field
  """
  @spec to_marc(JPMarc.ControlField.t)::String.t
  def to_marc(field) do
     field.value <> Const.fs
  end

end
