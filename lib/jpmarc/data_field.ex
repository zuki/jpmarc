defmodule JPMarc.DataField do
  @moduledoc """
  Tools for working with JPMARC DataFields
  """

  alias JPMarc.SubField
  @fs "\x1e" # Field separator

  @typedoc """
      Type that represents `JPMarc.DataField` struct.

      This is constructed with `:tag` as String, `:ind1` as String, `:ind2` as String and `:subfields` as List of `JPMarc.SubField.t`
  """
  @type t :: %__MODULE__{tag: String.t, ind1: String.t, ind2: String.t, subfields: [SubField.t]}
  @derive [Poison.Encoder]
  defstruct tag: "", ind1: " ", ind2: " ", subfields: []

  @doc """
  Returns a list of SubFields with `code` in `field`, [] when it doesn't exist

  `code` is either of :all, code as String or List of code.
  Default is `:all`.
  """
  @spec subfields(t, (atom|String.t|[String.t]))::[SubField.t]
  def subfields(field, code \\ :all) do
    cond do
      code == :all ->
        field.subfields
      is_list(code) ->
        field.subfields |> Enum.filter(&Enum.member?(code, &1.code))
      is_binary(code) ->
        field.subfields |> Enum.filter(&(&1.code == code))
      true -> []
    end
  end

  @doc """
  Returns a Subfield value with `code` in `field`, `""` when it doesn't exist

  `code` is either of :all, code as String or List of code.
  Default is `:all`.
  """
  @spec subfield_value(t, (atom|String.t|[String.t]), String.t)::[String.t]
  def subfield_value(field, code \\ :all, joiner \\ " ") do
    subfields(field, code) |> Enum.map(&("#{&1.value}")) |> Enum.join(joiner)
  end

  @doc """
  Return the MARC Format of the data field
  """
  @spec to_marc(t)::String.t
  def to_marc(field) do
    subfields = field.subfields |> Enum.map(&SubField.to_marc/1) |> Enum.join
    field.ind1 <> field.ind2 <> subfields <> @fs
  end

  @doc """
  Return a tuple representing its xml element
  """
  @spec to_xml(t)::tuple
  def to_xml(df) do
    subfields = df.subfields |> Enum.map(&SubField.to_xml/1)
    {:datafield, %{tag: df.tag}, subfields}
  end

  @doc """
  Return a text representing of the field
  """
  @spec to_text(t)::String.t
  def to_text(df) do
    subfields = df.subfields |> Enum.map(&SubField.to_text/1)
    "#{df.tag} #{df.ind1}#{df.ind2} #{Enum.join(subfields, " ")}"
  end

  defimpl Poison.Encoder, for: JPMarc.DataField do
    def encode(df, _options) do
      subfields = df.subfields |> Enum.map(&Poison.encode!/1) |> Enum.join(",")
       "{\"#{df.tag}\":{\"ind1\":\"#{df.ind1}\",\"ind2\":\"#{df.ind2}\",\"subfields\":[#{subfields}]}}"
    end
  end

  defimpl Inspect do
    def inspect(%JPMarc.DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}, _opts) do
      "#{tag} #{ind1}#{ind2} #{Enum.join(subfields, " ")}"
    end
  end

  defimpl String.Chars, for: JPMarc.DataField do
    def to_string(%JPMarc.DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}) do
      "#{tag} #{ind1}#{ind2} #{Enum.join(subfields, " ")}"
    end
  end

end
