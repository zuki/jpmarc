defmodule JPMarc.ControlField do
  @typedoc """
      Type that represents `JPMarc.ControlField` struct with `:tag` as binary and `:value` as binary.
  """
  @type t :: %JPMarc.ControlField{tag: binary, value: binary}
  defstruct tag: "", value: ""
end
