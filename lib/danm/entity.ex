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
  return the sub modules in the design as a list of names
  """
  def sub_modules(b)

  @doc ~S"""
  return the sub module with the given instance name
  """
  def sub_module_at(b, name)

  @doc ~S"""
  return the ports in the design as a list of names
  """
  def ports(b)

  @doc ~S"""
  return the port as {dir, w} tuple with the given port name
  """
  def port_at(b, name)

end
