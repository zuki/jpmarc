defmodule JPMarc.ControlField do
  @moduledoc """
  Tools for working with JPMARC ControlFields
  """

  @fs "\x1e" # Field separator

  @typedoc """
      Type that represents `JPMarc.ControlField` struct

      This is constructed with `:tag` as String and `:value` as String.
  """
  @type t :: %__MODULE__{tag: String.t, value: String.t}
  @derive [Poison.Encoder]
  defstruct tag: "", value: ""

  @doc """
    Return the MARC Format of the control field
  """
  @spec to_marc(t)::String.t
  def to_marc(field) do
     field.value <> @fs
  end

  @doc"""
  Return a tuple representing its xml element
  """
  @spec to_xml(t)::tuple
  def to_xml(cf) do
    {:controlfield, %{tag: cf.tag}, cf.value}
  end

  @doc"""
  Return a text representing of this field
  """
  @spec to_text(t)::String.t
  def to_text(cf) do
    "#{cf.tag} #{cf.value}"
  end

  defimpl Poison.Encoder, for: JPMarc.ControlField do
    def encode(cf, _options), do: "{\"#{cf.tag}\":\"#{cf.value}\"}"
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
