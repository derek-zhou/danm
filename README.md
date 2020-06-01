Design Automation aNd Manipulation
==================================

DANM, short for "Design Automation aNd Manipulation", is a tool written by Derek for use in synthesizable RTL design. It can do the following:

 * simplify authoring
 * generate html documentation
 * generate design statistic and design rule check

# Install #

DANM is written in elixir. to install simply add "danm" in your deps section of your mix.exs file. danm does not depend on anything beyond what you have from a simple `mix new` run, although it can make use of the config system of elixir.

# Usage #
Make sure you have elixir installed and danm added as a dependency. RTL file can be entered in one of the following mode:

 * verilog-1995 .v files. Please put them under verilog_path configed paths.
 * exs files. please see the examples dir for examples. All design must be under the Danm.Schematic namespace
 * ex filess. This is exactly the same file as above, but compiled together with your other elixir files, if you have any.

Danm will search a design entity first as a compiled-in ex file, failing that, from a exs file from the `elixir_path`, failing that, from a verilog file from the `verilog_path`. You have 2 ways to build rtl:

 * calling Danm.build, ... functions yourself for better control
 * calling Danm.auto_build([names]) function. it will run design check, build verilog and html output automatically. 

Please check the api doc of the package Danm.

# composing rtl in elixir #

The idea is to compose rtl conceptually like making a schematic. Each design is an elixir module and shall provide a build/1 function, that take an input, which is a blank schematic with parameters in place, and generate an output, which is a finished schematic. The parameters are similiar to verilog parameters, but enhanced to support any data, not just integers. The module shall `import Danm.Schematic`,  and call the api to build up the rtl piece wise. Damn means to give you better expressiveness in writing your rtl in elixir. Danm's API encourage an narrative coding style that make heavy use of the elixir's pipe operator, below is an example. Please refer to the example dir for more usable examples. 

    def build(s) do
      w = s.params["width"] || 16
      s
      |> add("spram_simple", as: "hi", parameters: %{"width" => w})
      |> add("spram_simple", as: "lo", parameters: %{"width" => w})
      |> connect(["hi/dout"], as: "hi_dout")
      |> connect(["lo/dout"], as: "lo_dout")
      |> assign("hi_dout, lo_dout", as: "dout")
      |> auto_connect()
      |> auto_expose()
    end

You do not need to master elixir to do that, as the danm api is very intuitive. Knowing more about elixir will definitly help you achieve more.

Once your rtl is composed, you can build it and export the verilog so it can be consumed by downstream tools. For simulation, I recommend the free software verilator, which work nicely with the verilog output from danm. You can write your validation framework in elixir as well, using the ExUnit framework, but that is beyond the scope of Danm, and is specific to the nature of your design.

# FAQs #

Why only verilog 95?

The author feel verilog 95 is already adequate as an exchange format among tools. It is obviously inadequate for authoring design, but so are all later verilog standards. The point of Danm is to author not in verilog, but in a language that is extendable and much more expressive.

Why only synthesizable subset of verilog?

Synthesizable RTL and test bench designs are completely different things. The author feels that they should not mix; and one should use better tool tailored for each task. Verilog or System verilog can be a choice to author test bench code in simple cases. For comlicated cases, the author believe you should keep the verilog part minimal and use more sofisticated tools. Danm does not impose on which way you choose.

