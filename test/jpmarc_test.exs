defmodule JPMarcTest do
  use ExUnit.Case

  setup_all do
    record = JPMarc.parse_file("marc.mrc")
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
    assert length(record.fields) == 41
  end

  test "Leader", %{leader: leader} do
    assert leader.type == "a"
    assert leader.level == "m"
    assert leader.status == "c"
  end

  test "control_fields", %{control_fields: control_fields} do
    assert length(control_fields) == 5

    first_control_field = Enum.at(control_fields, 0)
    assert first_control_field.tag == "001"
    assert first_control_field.value == "025011131"
  end

  test "data_fields", %{data_fields: data_fields} do
    assert length(data_fields) == 36

    first_data_field = Enum.at(data_fields, 0)
    assert first_data_field.indicator == "  "
    assert length(first_data_field.subfields) == 2

    first_subfield = Enum.at(first_data_field.subfields, 0)
    assert first_subfield.code == "a"
    assert first_subfield.value == "22339211"
  end
end
