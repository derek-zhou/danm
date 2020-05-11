defprotocol Danm.Entity do
  @moduledoc """
  A design entity protocol.
  """

  @doc ~S"""
  elaborate the design into a concrate one
  """
  def elaborate(b)

  @doc ~S"""
  return the doc string of the design
  """
  def doc_string(b)

  @doc ~S"""
  return the type string of the design
  """
  def type_string(b)

  @doc ~S"""
  return the sub modules in the design as a map from insts= name to instances
  """
  def sub_modules(b)

end
