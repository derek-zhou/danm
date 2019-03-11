RTL design with DANM
====================

In the previous article hierachical design is introduced. If all you
want to do is to connect verilog modules together, that should be
enough and is already quite useful. DANM can also do behavior RTL
design, and with that you could have complete design in danm smalltalk
and enjoy much more benefits. 

Please note that danm does not do test bench oriented behavior
modeling. For that you can use verilog or system-verilog, which are
much more suited for the job.

# Concepts #

## Constant ##

A constant is a verilog constant with width. The string formats are:

 * 3b000
 * 4d12
 * 8hFF

WHich is very closed to verilog; just without the apostrophe. Even
simpler to type. If there is no width it is assumed to be the same as
other elements in the same expression, or the l-value in assignment,
or 32 if no clue can be found. This is called DWIW: "do what I mean".

## identifier ##

An identifier is a reference to a wire. The string form is just the
name of the wire. 

## expression ##

Both constant and identifier are expressions. Expressions can also be
much more complex, with operators on sub expressions. Expression
usually have a string representation which is similiar to, but has
small difference from verilog expression strings. Even more complex
expression does not have simple string form and has to be modeled by
complex verilog structures. 

The purpose of an expression is to drive a wire. In this case the wire
has the same width as the width of the expression, and can drive pins,
ports, or participate in expression for other wires via an identifier
to itself. The most basic usage for expression is to assign it to a
wire:

	self let: 'wire1' be: 'wire0^wire2'.
	
There are much more ways to do similiar things or more advance things,
please chack the 'schematic_building.st' source code.

## sequential elements ##

The only 2 sequential elements allowed are flops and latches. They are
also expressions. They have to be constructed explicitly. No more
inferred latch.

# opertors #

The most basic expressions are identifiers and constants. To build
more complex operators, you need to use operators. 

## unary operators ##

These operators take one operand. In string form you write the opeator
in front of the operand. They also have the highest priority.

 * ~ bit invert
 * | or bus
 * & and bus
 * ^ xor bus
 
They have the same meaning as in verilog.

## binary operators ##

These operator takes 2 operands, and is written as infix. They has
second to highest priority in evaluation.

 * &|^
 * +-
 * <>=
 
They have the same meaning as in verilog. DANM also defines a few
extras:

 * , concatenate. so you can write '(a,b)' instead of '{a,b}' 
 * $ flop. 'a$clk' is a flop after a on posedge clk
 * @ latch. 'a@clk' is a D-latch after a with positive clk
 
## compound operators ##

DANM also defined a few operators that tkae 3 or more operands. 

### choice operator ###

For example:

    'a?b:c'

a can be more than 1 bit wide. If a is 2 bit wide, you can write:

    'a?b:c:d:e'
	
DANM will generate legal verilog based on what you mean.

### if operator ###

Often you need to write if ... else if ... else if ... else. For that
you can write an array of associations:

    { 'a' -> 'x'.
	  'b' -> 'y'.
	  1 -> 'z' }

And it can be nested. 

### case operator ###

A case statement can also be expressed as an array of association:

	self let: 'x' beCases: 
		{ '0' -> 'x0'.
		  '1' -> 'x1'.
		  nil -> 'x2' } on: 'con'.
		  
You cannot nest cases though. 

# assertion #

An assertion is a schematic module that has no outputs. It has
expression inside and the generated verilog contains statements to
stop the simulation if certain condition is met. For example:

	self assert: '~vld|rdy'.

There are a few more assertion defined in danm, or you can subclass
and define more. Check the source code in DANMAssertion.st

# advance usages #

Keep in mind that youe schematic is a smalltalk class; you have all
the power of smalltalk in your disposal. There is some examples
included in DANM that show case the expressiveness of DANM; however
that is only a small part of the possibilities. 



	
