defmodule Danm.Schematic.RrArbiter do
  @moduledoc """
  I am a round robin arbiter, that grant access according to request. 
  If you care about fairness, do not use me and use scan_arbiter instead.
  I am smaller and faster, but imprecise. I do not waste cycle and I will not
  starve anyone.
  """

  import Danm.Schematic

  def build do
    %Danm.Schematic{name: "rr_arbiter"}
  end
  
end
