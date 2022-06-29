defprotocol Danm.Entity do
  @moduledoc false

  @doc ~S"""
  elaborate the design into a concrate one
  """
  def elaborate(b)

  @doc ~S"""
  return the name of the design
  """
  def name(b)

  @doc ~S"""
  return the type string of the design
  """
  def type_string(b)

  @doc ~S"""
  return the ports in the design as a list of names
  """
  def ports(b)

  @doc ~S"""
  return the port as {dir, w} tuple with the given port name
  """
  def port_at!(b, name)

  @doc ~S"""
  return true if port exist.
  """
  def has_port?(b, name)
end
