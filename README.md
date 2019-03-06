Design Automation aNd Manipulation
==================================

DANM, short for "Design Automation aNd Manipulation", is a tool written by
Derek for use in synthesizable RTL design. It can do the following:

 * simplify authoring
 * generate documentation
 * generate design statistic and design rule check
 * programmably manipulate the design

# Install #

DANM is written in gnu smalltalk. to install simply do "make" in the st
dir. what it does is simply make a smalltalk package and install in the .st
dir. 

# Usage #
Make sure you have gnu smalltalk installed. Then you write a small
smalltalk script like:

	"load the danm package"
	PackageLoader fileInPackage: 'DANM'.
	"paths is a list of search path where the modules are found, in either
	smalltalk or verilog"
	s1 := DANMLibrary moduleByName: 'valid_test' fromPaths: {'.'}.
	"check for problems"
	s1 checkDesign.
	"generate html docs in html/ dir"
	s1 generateHTMLAsTop.
	"write one single hierachical verilog file, for external simulation"
	s1 generateFullVerilogTo: '%1.v' % {s1 name}.
	"postprocess, this give each schematic a chance to do something, usually for synthesis"
	s1 postprocess.
	"flattening, for synthesis"
	s1 flattenAll.
	"optional, simple optimization step. this will not remove dangling signals"
	s1 optimizeNoTrim.
	"remove dangling signals as well"
	s1 optimize.
	"write one single flatten verilog file, for synthesis run"
	s1 generateFullVerilogTo: '%1_flat.v' % {s1 name}.

You can put everything in a Makefile as well. For detail documentation, please refer to the doc directory. 



