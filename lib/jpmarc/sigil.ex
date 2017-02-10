defmodule JPMarc.MarcSigil do
  @doc """
  Implement the "~M" sigil, which takes a string containig
  JPMARC representation and return JPMarc struct.
  """

  alias JPMarc
  alias JPMarc.ControlField, as: CF
  alias JPMarc.DataField, as: DF
  alias JPMarc.SubField, as: SF

  def sigil_M(lines, []), do: _M(lines, :ndl)
  def sigil_M(lines, 'n'), do: _M(lines, :ndl)
  #def sigil_M(lines, 'v'), do: _M(lines, :vufind)

  defp _M(lines, :ndl) do
    [leader|fields] = lines |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.map(fn (l) ->
      case l do
        <<"LDR\t \t", leader::binary>> ->
          JPMarc.parse_leader(leader)
        <<"FMT", _::binary>> -> []
        <<"SYS", _::binary>> -> []
        <<tag::bytes-size(3), "\t \t", value::binary>> ->
          if String.starts_with?(value, "|") do
            make_data_field(tag, " ", " ", value)
          else
            %CF{tag: tag, value: value}
          end
        <<tag::bytes-size(3), ind1::bytes-size(1), "\t \t", value::binary>> ->
          make_data_field(tag, ind1, " ", value)
        <<tag::bytes-size(3), ind1::bytes-size(1), ind2::bytes-size(1), "\t \t", value::binary>> ->
          make_data_field(tag, ind1, ind2, value)
        _ -> []
      end
    end) |> List.flatten()
    %JPMarc{leader: leader, fields: fields}
  end

  defp make_data_field(tag, ind1, ind2, value) do
    subfields = " " <> value
      |> String.split(" |", trim: true)
      |> Enum.map(&String.split(&1, " ", parts: 2))
      |> Enum.map(fn l -> %SF{code: List.first(l), value: List.last(l)} end)
    %DF{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
  end
end
