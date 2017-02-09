defmodule JPMarcTest do
  use ExUnit.Case

  setup_all do
    record = JPMarc.parse_file("test/data/test.mrc")
    {control_fields, data_fields} =
      Enum.split_with(record.fields, &(&1.__struct__ == JPMarc.ControlField))
    {:ok, [
      record: record,
      leader: record.leader,
      control_fields: control_fields,
      data_fields: data_fields]}
  end

  test "Read a marc file", %{record: record} do
    assert record.leader != nil
    assert length(record.fields) == 7
  end

  test "Leader", %{leader: leader} do
    assert leader.type == "a"
    assert leader.length == 276
  end

  test "control_fields", %{control_fields: control_fields} do
    assert length(control_fields) == 5

    first_control_field = Enum.at(control_fields, 0)
    assert first_control_field.tag == "001"
    assert first_control_field.value == "123456789012"
  end

  test "data_fields", %{data_fields: data_fields} do
    assert length(data_fields) == 2

    first_data_field = Enum.at(data_fields, 0)
    assert first_data_field.ind1 == " "
    assert first_data_field.ind2 == " "
    assert length(first_data_field.subfields) == 2

    first_subfield = Enum.at(first_data_field.subfields, 0)
    assert first_subfield.code == "c"
    assert first_subfield.value == "2000円"
  end

  test "write marc", %{record: record} do
    marc = JPMarc.to_marc(record)
    {:ok, org} = File.read("test/data/test.mrc")
    assert marc == org
  end
end
