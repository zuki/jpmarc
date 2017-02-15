# JPMarc

A library for using JPMARC in Elixir

## Installation

Add `jpmarc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:jpmarc, github: "zuki/jpmarc"}]
end
```

## Usage

````elixir
alias JPMarc.Record
alias JPMarc.Leader
alias JPMarc.ControlField, as: CF
alias JPMarc.DataField, as: DF
alias JPMarc.SubField, as: SF
import JPMarc.MarkSigil

# Read MARC file and process every MARC record

for record <- JPMarc.parse_file("marc.dat") do
  # Print a value of field 245, subfield a
  IO.puts Record.subfield_value(record, "245", "a")
end

# Construct a JPMarc.Record

leader = %Leader{}
t001 = %CF{tag: "001", value: "1234"}
t003 = %CF{tag: "003", value: "JTNDL"}
t245a = %SF{code: "a", value: "タイトル /"}
t245c = %SF{code: "c", value: "山田, 太郎 著."}
t245 = %DF{tag: "245", ind1: "0", ind2: "0", subfields: [t245a, t245c]}
record = %Record{leader: leader, control_fields: [t001, t003], data_fields: [t245]}

# Write records in MARC format
File.write("marc.dat", JPMarc.to_marc(record))

# Write records in XMLMARC format
File.write("marc.xml", JPMarc.to_xml(record))

# Write records in Mark-in-json format
File.write("marc.json", JPMarc.to_json(record))

# Write records in Text format
File.write("marc.txt", Record.to_text(record))
````

## ~m Sigil

Covert string in Text MARC format to JPMarc.Record.

````elixir
record = ~m"""
00276nam a2200109zi 4500
001 123456789012
003 JTNDL
005 20170209103923.0
007 ta
008 170209s2017    ja ||||g |||| |||||||jpn
020    $c 2000円 $z 978-4-123456-01-0
245 00 $a タイトル : $b 関連情報 / $c 山田太郎 著.
"""

IO.puts Record.subfield_value(record, "245", "a") # -> "タイトル : "
````

## API documents

````elixir
mix docs

open "doc/index.html"
````

## License

This software released under the MIT License.
