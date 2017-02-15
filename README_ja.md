# JPMarc

ElixirでJPMARCを扱うためのライブラリです。

## インストール

`mix.exs`に`jpmarc`を追加して、`mix deps.get`してください。

```elixir
def deps do
  [{:jpmarc, github: "zuki/jpmarc"}]
end
```

## 使い方

````elixir
alias JPMarc.Record
alias JPMarc.Leader
alias JPMarc.ControlField, as: CF
alias JPMarc.DataField, as: DF
alias JPMarc.SubField, as: SF
import JPMarc.MarkSigil

# MARCファイルを読んで、MARCレコードごとに処理

for record <- JPMarc.parse_file("marc.dat") do
  # フィールド 245、サブフィールド a の値を出力
  IO.puts Record.subfield_value(record, "245", "a")
end

# レコードの作成

leader = %Leader{}
t001 = %CF{tag: "001", value: "1234"}
t003 = %CF{tag: "003", value: "JTNDL"}
t245a = %SF{code: "a", value: "タイトル /"}
t245c = %SF{code: "c", value: "山田, 太郎 著."}
t245 = %DF{tag: "245", ind1: "0", ind2: "0", subfields: [t245a, t245c]}
record = %Record{leader: leader, fields: [t001, t003, t245]}

# ~mシジルによるレコードの作成
record = %Record{leader: %Leader{}, fields: [~m"001 1234", ~m"003 JTNDL", ~m"245 00 $a タイトル / $b 山田, 太郎 著."]}

# MARC形式で出力
File.write("marc.dat", JPMarc.to_marc(record))

# MARCXML形式で出力
File.write("marc.xml", JPMarc.to_xml(record))

# JSON形式で出力
File.write("marc.json", JPMarc.to_json(record))

# テキスト形式で出力
File.write("marc.txt", Record.to_text(record))
````

## ~m シジル

テキスト形式のMARCをJPMarc構造体に変換する。

````elixir
# レコード
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

# リーダー
leader = ~m"00276nam a2200109zi 4500"

# コントロールフィールド
cf = ~m"001 123456789012"

# データフィールド
df = ~m"245 00 $a タイトル : $b 関連情報 / $c 山田太郎 著."
````

## APIドキュメント

````elixir
mix docs

open "doc/index.html"
````

## ライセンス

このライブラリはMIT Licenseのもとで公開します。
