defmodule JPMarc.MarcSigil do
  @doc """
  Implement the "~M" sigil, which takes a string containig
  JPMARC representation and return JPMarc struct.
  """

  alias JPMarc.Record
  alias JPMarc.Leader
  alias JPMarc.ControlField, as: CF
  alias JPMarc.DataField, as: DF
  alias JPMarc.SubField, as: SF

  def sigil_m(text, []), do: _m(text, :jpmarc)
  def sigil_m(text, 'n'), do: _m(text, :ndl)
  #def sigil_m(text, 'v'), do: _m(text, :vufind)

  defp _m(text, :jpmarc) do
    lines = text |> String.split("\n") |> Enum.map(&String.trim_leading/1)
    if length(lines) == 1 do
      lines |> Enum.at(0) |> parse()
    else
      [leader | fields] =  lines |> Enum.map(&parse/1) |> List.flatten()
      %Record{leader: leader, fields: fields}
    end
  end

  defp _m(text, :ndl) do
    separator = "|"
    [leader|fields] = text |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.map(fn(line) ->
      case line do
        <<"LDR\t \t", leader::binary>> ->
          Leader.decode(leader)
        <<"FMT", _::binary>> -> []
        <<"SYS", _::binary>> -> []
        <<tag::bytes-size(3), "\t \t", value::binary>> ->
          if String.starts_with?(value, " |") do
            make_data_field(tag, " ", " ", value, separator)
          else
            %CF{tag: tag, value: value}
          end
        <<tag::bytes-size(3), ind1::bytes-size(1), "\t \t", value::binary>> ->
          make_data_field(tag, ind1, " ", value, separator)
        <<tag::bytes-size(3), ind1::bytes-size(1), ind2::bytes-size(1), "\t \t", value::binary>> ->
          make_data_field(tag, ind1, ind2, value, separator)
        _ -> []
      end
    end) |> List.flatten()
    %Record{leader: leader, fields: fields}
  end

  defp parse(line) do
    case line do
      <<tag::bytes-size(3), " ", ind1::bytes-size(1), ind2::bytes-size(1), " $", value::binary>> ->
        make_data_field(tag, ind1, ind2, "$" <> value, "$")
      <<tag::bytes-size(3), " ", value::binary>> ->
        %CF{tag: tag, value: value}
      <<leader::bytes-size(24)>> ->
        Leader.decode(leader)
      _ -> []
    end
  end

  defp make_data_field(tag, ind1, ind2, value, separator) do
    subfields = " " <> value
      |> String.split(" #{separator}", trim: true)
      |> Enum.map(&String.split(&1, " ", parts: 2))
      |> Enum.map(fn l -> %SF{code: List.first(l), value: List.last(l)} end)
    %DF{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
  end
end
