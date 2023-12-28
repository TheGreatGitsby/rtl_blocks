
Formal verification of a synchornous FIFO using non-deterministic constant methodology.

a non-deterministic constant is just a free-variable (similar to all inputs) that the formal engines constrain to
a single value per run.
The behavior of a non-deterministic constant
is the same as an input, if it were constrained to be $stable, (ie assume($stable(input))).  The Engines still have the freedom to use any
value it wishes, and therefor will analyze all combiniations, however, it cannot change for a single run.  Lets look at how we can leverage this in our formal analysis...

Memories/FIFOs are notoriously complex to formally verify due to the large state space and combination of values the tools must analyze, but with using an NDC, we can simplify
this.

- Lets first use some modeling code to keep track of the current FIFO fill level.  Having this will allow us to verify many of the FIFO signals including full,empty, almost full, etc...
- Once we know our fill level at all times, lets check that a FIFO input word is propagated through the FIFO and output at the expected read cycle. (ie if a fifo fill level is already 2 when a word in
  accepted, we would expect that the word exists at the fifo fifo head after 2 more reads.)
  - Since we know our fill level, all we need to do is latch the fill level and count down for each FIFO read that occurs.  When the count down fill level is zero, our word should be at the fifo output.
- We know we cant capture data every clock cycle and keep an array of countdowns - that would be way too complex. We just need a way to tell us when to start....
- If we create an NDC, then we can implement some modeling code that captures the fill level and performs the Read count down when that NDC values shows up at the write data input.
  - It may be hard to grasp this at first, but this fully verifies the FIFO because the formal engines can inject this NDC value at any point in the fifo fill level, AND it can use any value it wishes.
  - for a particular run, we dont care about all the other values that may exist in the FIFO, because the engine is analyzing this in "separate runs". remember that it will analyze constraints using all combinations of input values
    and FIFO positions since we have made no constraints on when the tool may inject an input data word that matches the NDC.
  

