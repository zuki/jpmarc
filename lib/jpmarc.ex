defmodule JPMarc do
  @moduledoc """
    Library for parsing JPMARC
  """

  @typedoc """
      Type that represents `JPMarc` struct with `:leader` as `JPMarc.Leader.t`, `:fiels` as List of `JPMarc.ControlField.t` or `JPMarc.DataField.t`
  """
  @type t :: %JPMarc{leader: JPMarc.Leader.t, fields: [JPMarc.ControlField.t | JPMarc.DataField.t]}
  defstruct leader: nil, fields: []

  @doc """
    Parse a marc file and return `JPMarc` struct or nil if a error occures when reading the specific file
  """
  @spec parse_file(binary)::(JPMarc.t|nil)
  def parse_file(file) do
    case File.read(file) do
      {:ok, marc} ->
        parse_record(marc)
      {:error, reason} ->
        IO.puts "Error occured: #{reason}"
        nil
    end
  end

  @doc """
    Parse a binary of marc and return `JPMarc` struct
  """
  @spec parse_record(binary)::JPMarc.t
  def parse_record(marc) do
    <<leader::bytes-size(24), rest::binary>> = marc
    leader = parse_leader(leader)
    length_of_dirs = leader.base - 24 - 1 # -1 for \x1e
    <<dir_block::bytes-size(length_of_dirs), "\x1e", data:: binary>> = rest

    directories = get_directories(dir_block)
    fields = for {tag, length, position} <- directories do
      tag_data = binary_part(data, position, length)
      parse_tag_data(tag, tag_data)
    end
    %__MODULE__{leader: leader, fields: fields}
  end

  defp get_directories(block), do: _get_directories(block, [])
  defp _get_directories("", acc) do
    Enum.reverse acc
  end
  defp _get_directories(<<tag::bytes-size(3), length::bytes-size(4), position::bytes-size(5), rest::binary>>, acc) do
    acc = [{tag, String.to_integer(length), String.to_integer(position)} | acc]
    _get_directories(rest, acc)
  end

  defp parse_leader(leader) do
    <<length::bytes-size(5), status::bytes-size(1), type::bytes-size(1),
      level::bytes-size(1), _::bytes-size(4), base::bytes-size(5), _::binary>> = leader
    %JPMarc.Leader{length: String.to_integer(length), status: status, type: type, level: level, base: String.to_integer(base)}
  end

  defp parse_tag_data(tag, <<ind1::bytes-size(1), ind2::bytes-size(1), "\x1f", rest::binary>> = data) do
    subfields = parse_subfields(rest)
    %JPMarc.DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
  end

  defp parse_tag_data(tag, data) do
    %JPMarc.ControlField{tag: tag, value: String.trim_trailing(data, "\x1e")}
  end

  defp parse_subfields(data) do
    data = String.trim_trailing(data, "\x1e")
    fields = String.split(data, "\x1f", trim: true)
      |> Enum.map(fn chunk ->
        <<code::bytes-size(1), value::binary>> = chunk
        %JPMarc.SubField{code: code, value: value}
    end)
  end
end
