defmodule JPMarc.ControlField do
  # Field separator
  @fs "\x1e"

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
     field.value <> @fs
  end

  defimpl Inspect do
    def inspect(%JPMarc.ControlField{tag: tag, value: value}, _opts) do
      "#{tag} #{value}"
    end
  end

  defimpl String.Chars, for: JPMarc.ControlField do
    def to_string(%JPMarc.ControlField{tag: tag, value: value}) do
      "#{tag} #{value}"
    end
  end

end
