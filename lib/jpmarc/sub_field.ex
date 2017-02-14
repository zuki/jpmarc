defmodule JPMarc.SubField do
  @moduledoc """
  Tools for working with JPMARC SubFields
  """

  @fs "\x1e" # Field separator
  @ss "\x1f" # Subfield separator

  @typedoc """
      Type that represents `JPMarc.SubField` struct

      This is constructed with `:code` as String and `:value` as String.
  """
  @type t :: %__MODULE__{code: String.t, value: String.t}
  defstruct code: "", value: ""

  @doc """
  Decode a string representation to JPMarc.SubField struct
  """
  @spec decode(String.t)::[t]
  def decode(data) do
    data = String.trim_trailing(data, @fs)
    String.split(data, @ss, trim: true)
      |> Enum.map(fn chunk ->
        <<code::bytes-size(1), value::binary>> = chunk
        %__MODULE__{code: code, value: value}
    end)
  end

  @doc """
    Return the MARC Format of the subfield
  """
  @spec to_marc(t)::String.t
  def to_marc(field) do
    @ss <> field.code <> field.value
  end

  @doc """
  Return a tuple representing its xml element
  """
  @spec to_xml(t)::tuple
  def to_xml(sf) do
    {:subfield, %{code: sf.code}, sf.value}
  end

  @doc"""
  Return a text representing its element
  """
  @spec to_text(t)::String.t
  def to_text(sf) do
    "$#{sf.code} #{sf.value}"
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
