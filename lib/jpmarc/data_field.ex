defmodule JPMarc.DataField do
  alias JPMarc.SubField

  # Field separator
  @fs "\x1e"

  @typedoc """
      Type that represents `JPMarc.DataField` struct.

      This is constructed with `:tag` as String, `:ind1` as String, `:ind2` as String and `:subfields` as List of `JPMarc.SubField.t`
  """
  @type t :: %JPMarc.DataField{tag: String.t, ind1: String.t, ind2: String.t, subfields: [SubField.t]}
  defstruct tag: "", ind1: " ", ind2: " ", subfields: []

  @doc """
    Return the MARC Format of the data field
  """
  @spec to_marc(JPMarc.DataField.t)::String.t
  def to_marc(field) do
    subfields = field.subfields
      |> Enum.map(&SubField.to_marc/1)
      |> Enum.join

    field.ind1 <> field.ind2 <> subfields <> @fs
  end

  @doc """
    Sort its subfields by code
  """
  @spec sort(JPMarc.DataField.t)::JPMarc.DataField.t
  def sort(field) do
    sfs = field.subfields |> Enum.sort(&(&1.code <= &2.code))
    %__MODULE__{field | subfields: sfs}
  end

  defimpl Inspect do
    def inspect(%JPMarc.DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}, _opts) do
      "#{tag} #{ind1} #{ind2} #{Enum.join(subfields, " ")}"
    end
  end

  defimpl String.Chars, for: JPMarc.DataField do
    def to_string(%JPMarc.DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}) do
      "#{tag} #{ind1} #{ind2} #{Enum.join(subfields, " ")}"
    end
  end

end
