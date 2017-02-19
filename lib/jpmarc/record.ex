defmodule JPMarc.Record do
  @moduledoc """
    Tools for working with JPMARC Record
  """
  import XmlBuilder
  alias JPMarc.Leader
  alias JPMarc.ControlField
  alias JPMarc.DataField
  alias JPMarc.SubField

  @rs "\x1d"   # Record separator
  @fs "\x1e"   # Field separator
  @ss "\x1f"   # Subfield separator
  @leader_length 24
  @valid_control_fields ~W(001 003 005 007 008) # Valied fields

  @typedoc """
      Type that represents `JPMarc.Record` struct

      This is constructed with `:leader` as `JPMarc.Leader.t`, `:fiels` as List of `JPMarc.ControlField.t` or `JPMarc.DataField.t`
  """
  @type t :: %__MODULE__{leader: Leader.t, fields: [ ControlField.t | DataField.t ]}
  @derive [Poison.Encoder]
  defstruct leader: nil, fields: []

  @doc """
  Return `true` if `tag` is a valid tag number as ControlField, otherwise `false`
  """
  @spec control_field?(String.t)::boolean
  def control_field?(tag), do: Enum.member?(@valid_control_fields, tag)

  @doc """
  Returns a list of Fields with `tag`, `ind1` and `ind2` in `record`, [] when it doesn't exist
  """
  @spec fields(JPMarc.Record.t, String.t, String.t, String.t)::[t]
  def fields(record, tag, ind1 \\ nil, ind2 \\ nil) do
    if control_field?(tag) do
      record.fields |> Enum.filter(&(&1.tag == tag))
    else
      case {tag, ind1, ind2} do
        {tag, nil, nil} ->
          record.fields |> Enum.filter(&(&1.tag == tag))
        {tag, ind1, nil} ->
          record.fields |> Enum.filter(&(&1.tag == tag && &1.ind1 == ind1))
        {tag, ind1, ind2} ->
          record.fields |> Enum.filter(&(&1.tag == tag && &1.ind1 == ind1 && &1.ind2 == ind2))
      end
    end
  end

  @doc """
  Returns first DataFields with `tag`, `ind1` and `ind2` in `record`, nil when it doesn't exist
  """
  @spec field(JPMarc.Record.t, String.t, String.t, String.t)::(t|nil)
  def field(record, tag, ind1 \\ nil, ind2 \\ nil), do: fields(record, tag, ind1, ind2) |> Enum.at(0)

  @doc """
  Returns a list of SubFields with `tag`, `ind1`, `ind2` and `code` in `record`, [] when it doesn't exist

  `code` is either of :all, `code` as String or List of `code`.
  Default is `:all`.
  """
  @spec subfields(t, String.t, (atom|String.t|[String.t]), String.t, String.t)::[SubField.t]
  def subfields(record, tag, code \\ :all, ind1 \\ nil, ind2 \\ nil) do
    fields = fields(record, tag, ind1, ind2)
    unless Enum.empty?(fields) do
      cond do
        code == :all ->
          fields |> Enum.map(&(&1.subfields))
        is_list(code) ->
          fields |> Enum.map(fn(df) ->
            df.subfields |> Enum.filter(&Enum.member?(code, &1.code))end)
        is_binary(code) ->
          fields |> Enum.map(fn(df) ->
            df.subfields |> Enum.filter(&(&1.code == code))end)
        true -> []
      end
    else
      []
    end
  end

  @doc """
  Returns first SubField with `tag`, `ind1`, `ind2` and `code` in `record`, [] when it doesn't exist

  `code` is either of :all, `code` as String or List of `code`.
  Default is `:all`.
  """
  @spec subfield(t, String.t, (atom|String.t|[String.t]), String.t, String.t)::SubField.t
  def subfield(record, tag, code \\ :all, ind1 \\ nil, ind2 \\ nil), do: subfields(record, tag, code, ind1, ind2) |> Enum.at(0)

  @doc """
  Returns a list of SubFields value with `tag`, `ind1`, `ind2` and `code` in `record`, `[]` when it doesn't exist

  `code` is either of :all, `code` as String or List of `code`.
  Default is `:all`.
  """
  @spec field_values(t, String.t, (atom|String.t|[String.t]), String.t, String.t, String.t)::[String.t]
  def field_values(record, tag, code \\ :all, ind1 \\ nil, ind2 \\ nil, joiner \\ " ") do
    if control_field?(tag) do
      if cf = field(record, tag), do: [cf.value], else: []
    else
      subfield_values(record, tag, code, ind1, ind2, joiner)
    end
  end

  @doc """
  Returns a list of Field values with `tag`, `ind1`, `ind2` and `code` in `record`, `nil` when it doesn't exist

  `code` is either of :all, `code` as String or List of `code`.
  Default is `:all`.
  """
  @spec field_value(t, String.t, (atom|String.t|[String.t]), String.t, String.t)::String.t
  def field_value(record, tag, code \\ :all, ind1 \\ nil, ind2 \\ nil, joiner \\ " "), do: field_values(record, tag, code, ind1, ind2, joiner) |> Enum.at(0)

  @doc """
  Returns a list of SubFields value with `tag`, `ind1`, `ind2` and `code` in `record`, `[]`when it doesn't exist

  `code` is either of :all, `code` as String or List of `code`.
  Default is `:all`.
  """
  @spec subfield_values(t, String.t, (atom|String.t|[String.t]), String.t, String.t, String.t)::[String.t]
  def subfield_values(record, tag, code \\ :all, ind1 \\ nil, ind2 \\ nil, joiner \\ " ") do
    subfields(record, tag, code, ind1, ind2) |> Enum.map(fn(sf) -> Enum.map(sf, &("#{&1.value}")) |> Enum.join(joiner) end)
  end

  @doc """
  Returns first SubFields value with `tag`, `ind1`, `ind2` and `code` in `record`, `nil` when it doesn't exist

  `code` is either of :all, `code` as String or List of `code`.
  Default is `:all`.
  """
  @spec subfield_value(t, String.t, (atom|String.t|[String.t]), String.t, String.t, String.t)::String.t
  def subfield_value(record, tag, code \\ :all, ind1 \\ nil, ind2 \\ nil, joiner \\ " "), do: subfield_values(record, tag, code, ind1, ind2, joiner) |> Enum.at(0)

  @doc """
    Decode the String of a marc and return `JPMarc.Record` struct
  """
  @spec from_marc(String.t)::t
  def from_marc(marc) do
    <<leader::bytes-size(@leader_length), rest::binary>> = marc
    leader = Leader.decode(leader)
    length_of_dirs = leader.base - @leader_length - 1 # -1 for @fs
    <<dir_block::bytes-size(length_of_dirs), @fs, data:: binary>> = rest

    directories = get_directories(dir_block)
    fields = for {tag, length, position} <- directories do
      tag_data = binary_part(data, position, length)
      parse_tag_data(tag, tag_data)
    end
    %__MODULE__{leader: leader, fields: fields}
  end

  @doc """
    Return the MARC Format of the JPMarc struct
  """
  @spec to_marc(t)::String.t
  def to_marc(record) do
    sorted = reset(record)
    {directories, data} = make_directories_data(sorted.fields)
    Leader.to_marc(sorted.leader) <> directories <> @fs <> data <> @rs
  end

  @doc """
  Return the MARCXML Format of the JPMarc struct
  """
  @spec to_xml(t)::tuple
  def to_xml(record) do
    sorted = reset(record)
    xml = sorted.fields |> Enum.map(fn(f) ->
      if Enum.member?(@valid_control_fields, f.tag),
        do: ControlField.to_xml(f),
        else: DataField.to_xml(f)
      end)
    fields_xml = [Leader.to_xml(sorted.leader)] ++ xml
    element(:record, nil, fields_xml)
  end

  @doc """
  Return the Text Format of the JPMarc struct
  """
  @spec to_text(t)::tuple
  def to_text(record) do
    sorted = reset(record)
    text = sorted.fields |> Enum.map(fn(f) ->
      if Enum.member?(@valid_control_fields, f.tag),
        do: ControlField.to_text(f),
        else: DataField.to_text(f)
      end)
    ([Leader.to_text(sorted.leader)] ++ text) |> Enum.join("\n")
  end

  @doc"""
  Return a json representing of the record
  """
  @spec to_json(t)::String.t
  def to_json(record) do
    reset(record) |> Poison.encode!()
  end

  @doc"""
  Construct a record from json formatted in the marc-in-json schema
  """
  @spec from_json(String.t)::t
  def from_json(json) do
    jmap = Poison.Parser.parse!(json)
    leader = Map.get(jmap, "leader") |> Leader.decode()
    fields = Map.get(jmap, "fields") |> Enum.map(&Map.to_list/1) |> Enum.map(fn ([field]) ->
      case field do
        {tag, %{"ind1" => ind1, "ind2" => ind2, "subfields" => sflds}} ->
          subfields = sflds
            |> Enum.map(&Map.to_list/1)
            |> Enum.map(fn ([{code, value}]) -> %SubField{code: code, value: value} end)
          %DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
        {tag, value} ->
          %JPMarc.ControlField{tag: tag, value: value}
      end
    end)
    %JPMarc.Record{leader: leader, fields: fields}
  end

  def reset(record) do
    sorted = sort(record)
    {directories, data} = make_directories_data(sorted.fields)
    marc = Leader.to_marc(sorted.leader) <> directories <> @fs <> data <> @rs
    new_leader = %Leader{sorted.leader | length: byte_size(marc), base: (@leader_length + 1 + byte_size(directories))}
    %__MODULE__{sorted | leader: new_leader}
  end

  @doc """
    Sort its fields by tag and subfields of field
  """
  @spec sort(t)::t
  def sort(record) do
    {control_fields, data_fields} = Enum.split_with(record.fields, &(&1.__struct__ == ControlField))
    sorted_control_fields = control_fields |> Enum.sort(&(&1.tag <= &2.tag))
    {t880, rest} = Enum.split_with(data_fields, &(&1.tag == "880"))
    sorted_data_fields = (rest |> Enum.sort(&(&1.tag<>&1.ind1<>&1.ind2 <= &2.tag<>&2.ind1<>&2.ind2)))
        ++ (t880 |> Enum.sort(&(DataField.subfield_value(&1, "6") <= DataField.subfield_value(&2, "6"))))
    %__MODULE__{record | fields: sorted_control_fields ++ sorted_data_fields}
  end

  defp get_directories(block), do: _get_directories(block, [])
  defp _get_directories("", acc) do
    Enum.reverse acc
  end
  defp _get_directories(<<tag::bytes-size(3), length::bytes-size(4), position::bytes-size(5), rest::binary>>, acc) do
    acc = [{tag, String.to_integer(length), String.to_integer(position)} | acc]
    _get_directories(rest, acc)
  end

  defp parse_tag_data(tag, <<ind1::bytes-size(1), ind2::bytes-size(1), @ss, rest::binary>>) do
    subfields = SubField.decode(rest)
    %DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
  end
  defp parse_tag_data(tag, data) do
    %ControlField{tag: tag, value: String.trim_trailing(data, @fs)}
  end

  defp make_directories_data(fields), do: _make_directories_data(fields, {[], []}, 0)
  defp _make_directories_data([], {dir, data}, _pos),
    do: {
      dir |> Enum.reverse |> Enum.join,
      data |> Enum.reverse |> Enum.join
    }
  defp _make_directories_data([head|tail], {dir, data}, pos) do
    marc = case head.__struct__ do
      ControlField -> ControlField.to_marc(head)
      DataField -> DataField.to_marc(head)
    end

    length = byte_size(marc)
    length_str = length |> Integer.to_string |> String.pad_leading(4, "0")
    pos_str = pos |> Integer.to_string |> String.pad_leading(5, "0")

    _make_directories_data(tail, {[head.tag <> length_str <> pos_str|dir] , [marc|data]}, pos + length)
  end

  defimpl Inspect do
    def inspect(%JPMarc.Record{leader: leader, fields: fields}, _opts) do
      "#{leader}\n#{Enum.join(fields, "\n")}"
    end
  end

  defimpl String.Chars, for: JPMarc.Record do
    def to_string(%JPMarc.Record{leader: leader, fields: fields}) do
      "#{leader}, #{Enum.join(fields, "\n")}"
    end
  end

end
