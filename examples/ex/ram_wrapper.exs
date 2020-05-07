defmodule Danm.Schematic.RamWrapper do

  import Danm.Schematic

  def build(s) do
    w = s.params[:width] || 16
    s
    |> add_instance_of("spram_simple", as: "hi", parameters: %{"width" => w})
    |> add_instance_of("spram_simple", as: "lo", parameters: %{"width" => w})
    |> connect(["hi/dout"], as: "hi_dout")
    |> connect(["lo/dout"], as: "lo_dout")
    |> auto_connect()
    |> auto_expose()
  end

end
