defmodule JPMarc.SubField do
  @typedoc """
      Type that represents JPMarc.SubField struct with :code as binary and :value as binary.
  """
  @type t :: %JPMarc.SubField{code: binary, value: binary}
  defstruct code: "", value: ""
end
