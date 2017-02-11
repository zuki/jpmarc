defmodule JPMarc.ControlField do
  @moduledoc"""
  Tools for working with JPMARC ControlFields
  """

  @fs "\x1e" # Field separator

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

  @doc"""
  Return a tuple representing its xml element
  """
  @spec to_xml(JPMarc.ControlField.t)::tuple
  def to_xml(cf) do
    {:controlfield, %{tag: cf.tag}, cf.value}
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
