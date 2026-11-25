# How qubit values depend on each other

*An interactive tutorial in Hello Qubits, written out in full so that it can be read, taught or followed without the game, by people or by AI models.*

Two qubits are described by 15 numbers, called values. You cannot choose them freely: they depend on each other in a few ways that you can learn to see. This tutorial shows those ways one at a time, as puzzles. It follows on from the Hello Qubits puzzles (and the Hello Qiskit puzzles in the Qiskit textbook, especially Level 4 and its Bloch mode).

## How to use this file

- **Playing the game:** run Hello Qubits and choose *Interdependency tutorial* on the title screen. Each puzzle below is one screen.
- **Reading it:** each puzzle gives the starting values, the buttons and exactly what each does, the goal, a solution, and what it shows. Every number here was produced by the simulator in `tools/tutorial_engine.py`, which does exactly what the game does.
- **Teaching from it (people or AI tutors):** take one puzzle at a time. Before revealing what happens, ask the learner to predict it. Don't invent numbers: compute them with `tools/tutorial_engine.py` (needs only numpy), or use the ones given here.

## Conventions

- Two qubits, called qubit 1 and qubit 2.
- A value is a number from -1 to +1. In the game: black circle +1, white circle -1, grey 0.
- Values are written with the qubit number after each letter: X1 is X on qubit 1, Z1Z2 is the correlation of the Z outputs of both qubits, Y1X2 is Y on qubit 1 with X on qubit 2. (In code, `tools/tutorial_engine.py` writes these as two-letter strings, first letter qubit 1: `XI`, `ZZ`, `YX`.)
- A **turn about a pole** G by angle theta applies exp(-i theta G / 2). For example ry(theta) on qubit 1 is a turn about Y1 by theta, and rx(theta) is a turn about X1.
- The game board is the diamond from Hello Qubits, extended with the Y values: qubit 1's own values (Z1, X1, Y1) run down the left edge, qubit 2's down the right edge, and each correlation sits where its two rows meet.

## 0. The bag of values

Each value is a number between -1 and +1 for one way of asking the qubits for an output. For X, Y or Z on one qubit: +1 means certain to output 0, -1 certain to output 1, 0 completely random. For a correlation such as Z1Z2: +1 means the two Z outputs certainly agree, -1 certainly disagree, 0 random. Each combination of letters is called a Pauli word. Two qubits have 15 values, three have 63, n have 4^n - 1. Together they describe the qubits completely. We call them the bag of values.

### Puzzle 0.1: Fifteen values

Hello Qubits showed 8 values. Here are all 15: the Y values are back.

Each circle is one value: black is +1, white is -1, grey is 0. The number is shown too. Qubit 1's own values run down the left edge, qubit 2's down the right. Correlations sit where their rows meet.

Warm-up: make X1X2 = +1.

- **Board shows:** all 15 values.
- **Start:** Z2 = +1.000, Z1 = +1.000, Z1Z2 = +1.000.
- **Buttons:**
  1. *h on qubit 1*: turn about (X1 + Z1)/sqrt2 by +1 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2, Y1, Y1Z2, Y1X2, Y1Y2.
  2. *h on qubit 2*: turn about (X2 + Z2)/sqrt2 by +1 pi. Can move: Z2, X2, Y2, Z1Z2, Z1X2, Z1Y2, X1Z2, X1X2, X1Y2, Y1Z2, Y1X2, Y1Y2.
  3. *x on qubit 1*: turn about X1 by +1 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, Y1, Y1Z2, Y1X2, Y1Y2. Discs: (Z1, Y1), (Z1Z2, Y1Z2), (Z1X2, Y1X2), (Z1Y2, Y1Y2).
- **Goal:** X1X2 = +1 (within 0.05).
- **A solution:** buttons 1, 2. Afterwards: X2 = +1.000, X1 = +1.000, X1X2 = +1.000.
- **What it shows:** The h gates moved certainty from the Z values to the X values, a whole row at a time. Everything in this tutorial is about how values move together.

## 1. Discs

Two values that anticommute act like a point in a disc of radius 1: their squares add up to at most 1. A gate can turn the point around the disc. The disc has a pole: a third value, the product of the two, which the turn leaves alone. Counting rule: write the two words one above the other, qubit by qubit, and count the qubits where both have a letter (not I) and the letters differ. If the count is odd they anticommute and form a disc; if even, they commute and don't. The pole is the letter-wise product: X times Y is Z, Y times Z is X, Z times X is Y, a letter times itself is I, a letter times I is that letter (up to a sign, which doesn't matter here).

### Puzzle 1.1: A partial turn

Gates turn values like a point in a disc. The disc on the right shows the point (X1, Z1).

ry(pi/4) turns qubit 1 by an eighth of a turn, from Z1 towards X1.

Turn until X1 = +1.

- **Board shows:** Z1, X1, Y1 only.
- **Start:** Z1 = +1.000.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, X1. Discs: (Z1, X1).
- **Goal:** X1 = +1 (within 0.05).
- **A solution:** buttons 1, 1. Afterwards: X1 = +1.000.
- **What it shows:** Halfway, X1 and Z1 were both 0.707: the certainty was shared. X1 squared plus Z1 squared can never go above 1. The turn left Y1 alone: Y1 is the pole of this disc.

### Puzzle 1.2: The third axis

Y1 is the third axis. An rx gate turns about the pole X1, so it moves the disc (Z1, Y1) and leaves X1 alone.

Make Y1 = +1.

- **Board shows:** Z1, X1, Y1 only.
- **Start:** Z1 = +1.000.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, X1. Discs: (Z1, X1).
  2. *rx(pi/4) on qubit 1*: turn about X1 by +0.25 pi. Can move: Z1, Y1. Discs: (Z1, Y1).
  3. *rx(-pi/4) on qubit 1*: turn about X1 by -0.25 pi. Can move: Z1, Y1. Discs: (Z1, Y1).
- **Goal:** Y1 = +1 (within 0.05).
- **A solution:** buttons 3, 3. Afterwards: Y1 = +1.000.
- **What it shows:** X1, Y1 and Z1 together form a ball: X1 squared plus Y1 squared plus Z1 squared is at most 1. Each pair is a disc, and the third is its pole.

### Puzzle 1.3: Discs everywhere

Any two values that anticommute form a disc, not just X, Y and Z on one qubit.

Counting rule: line up the two words. Count the qubits where both have a letter and the letters differ. Odd: a disc. Its pole is their product (X times Y is Z, Y times Z is X, Z times X is Y).

Hover over each button to see the discs its pole turns, then try them. Press Next when ready.

- **Board shows:** all 15 values.
- **Start:** Z2 = +1.000, X1 = +1.000, X1Z2 = +1.000.
- **Buttons:**
  1. *turn about Y1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  2. *turn about Z1Z2*: turn about Z1Z2 by +0.25 pi. Can move: X2, Y2, Z1X2, Z1Y2, X1, X1Z2, Y1, Y1Z2. Discs: (X2, Z1Y2), (Y2, Z1X2), (X1, Y1Z2), (X1Z2, Y1).
  3. *turn about Y1Z2*: turn about Y1Z2 by +0.25 pi. Can move: X2, Y2, Z1, Z1Z2, X1, X1Z2, Y1X2, Y1Y2. Discs: (X2, Y1Y2), (Y2, Y1X2), (Z1, X1Z2), (Z1Z2, X1).
  4. *turn about X1Y2*: turn about X1Y2 by +0.25 pi. Can move: Z2, X2, Z1, Z1Y2, X1Z2, X1X2, Y1, Y1Y2. Discs: (Z2, X1X2), (X2, X1Z2), (Z1, Y1Y2), (Z1Y2, Y1).
- **Goal:** none, explore.
- **More:** Worked examples of the counting rule. X1 and Z1: they differ on qubit 1, count 1, a disc with pole Y1. Z1Z2 and X1X2: they differ on both qubits, count 2, no disc. X1 and Z1Z2: they differ on qubit 1 only (qubit 2 has a letter in only one word), count 1, a disc with pole Y1Z2. Z1Z2 and Z1X2: qubit 1 has Z and Z (same), qubit 2 has Z and X, count 1, a disc with pole Y2. For two qubits, every value belongs to 4 discs, and there are 20 discs in all.

## 2. One turn moves many discs

A turn about a pole turns every disc that has that pole, all at once and by the same angle. A pole on qubit 1 only anticommutes with words that have a letter on qubit 1, so a gate on some qubits can never change a value that only involves other qubits (locality). It can still change correlations that reach the qubits it acts on.

### Puzzle 2.1: Whole rows

A turn turns every disc with its pole. ry on qubit 1 has pole Y1, and Y1 is the pole of four discs. Hover over the button to see them.

Make X1 = +1 and X1X2 = +1 at the same time.

- **Board shows:** all 15 values.
- **Start:** X2 = +1.000, Z1 = +1.000, Z1X2 = +1.000.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
- **Goal:** X1 = +1, X1X2 = +1 (within 0.05).
- **A solution:** buttons 1, 1. Afterwards: X2 = +1.000, X1 = +1.000, X1X2 = +1.000.
- **What it shows:** Both discs turned together. This is what Hello Qiskit's Bloch mode meant by combining 'whole rows': one gate on qubit 1 turns every value in qubit 1's Z and X rows.

### Puzzle 2.2: Locality

A turn only moves values that anticommute with its pole. A pole on one qubit only anticommutes with words that have a letter on that qubit.

Make X1 = Z1 = 0.707 and Z2 = -1. Watch which values each button can touch.

- **Board shows:** all 15 values.
- **Start:** Z2 = +1.000, Z1 = +1.000, Z1Z2 = +1.000.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  2. *ry(pi/4) on qubit 2*: turn about Y2 by +0.25 pi. Can move: Z2, X2, Z1Z2, Z1X2, X1Z2, X1X2, Y1Z2, Y1X2. Discs: (Z2, X2), (Z1Z2, Z1X2), (X1Z2, X1X2), (Y1Z2, Y1X2).
- **Goal:** X1 = +0.707, Z1 = +0.707, Z2 = -1 (within 0.05).
- **A solution:** buttons 1, 2, 2, 2, 2. Afterwards: Z2 = -1.000, Z1 = +0.707, Z1Z2 = -0.707, X1 = +0.707, X1Z2 = -0.707.
- **What it shows:** Turns on qubit 2 never moved X1 or Z1. But they did move correlations such as Z1Z2 and X1Z2, which reach qubit 2.

## 3. Radius is a budget

A disc's point can be anywhere inside it. When it is inside, the missing certainty is elsewhere in the bag. For a pure state (no noise) the squares of all 15 values add up to exactly 3 (for n qubits, 2^n - 1), and turns never change this total. The two values of a disc and its pole also share a budget of 1, so a loud pole squeezes every disc it belongs to. Entanglement is certainty moving from single-qubit values into correlations. A value at +1 or -1 is saturated: it is on the edge of every disc it belongs to.

### Puzzle 3.1: A loud pole squeezes

A disc and its pole share one budget: X1 squared plus Y1 squared plus Z1 squared is at most 1.

Here Y1 = 0.707, so the disc (Z1, X1) is squeezed to radius 0.707 (the dashed circle).

Turn the point to X1 = 0.707. Can you get X1 all the way to 1?

- **Board shows:** Z1, X1, Y1 only.
- **Start:** Z1 = +0.707, Y1 = +0.707.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, X1. Discs: (Z1, X1).
- **Goal:** X1 = +0.707, Z1 = +0 (within 0.05).
- **A solution:** buttons 1, 1. Afterwards: X1 = +0.707, Y1 = +0.707.
- **What it shows:** No: ry turns about Y1, so Y1 stays at 0.707 and keeps the disc small. A loud pole squeezes every disc it belongs to.

### Puzzle 3.2: Entanglement takes the budget

These qubits are in a Bell state: Z1Z2 = X1X2 = +1, Y1Y2 = -1, and every single-qubit value is 0. The budget (all squares add up to 3) is in the correlations.

Make X1Z2 = +1 and Z1X2 = -1. Keep an eye on the disc (Z1, X1).

- **Board shows:** all 15 values.
- **Start:** Z1Z2 = +1.000, X1X2 = +1.000, Y1Y2 = -1.000.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  2. *ry(pi/4) on qubit 2*: turn about Y2 by +0.25 pi. Can move: Z2, X2, Z1Z2, Z1X2, X1Z2, X1X2, Y1Z2, Y1X2. Discs: (Z2, X2), (Z1Z2, Z1X2), (X1Z2, X1X2), (Y1Z2, Y1X2).
- **Goal:** X1Z2 = +1, Z1X2 = -1 (within 0.05).
- **A solution:** buttons 1, 1. Afterwards: Z1X2 = -1.000, X1Z2 = +1.000, Y1Y2 = -1.000.
- **What it shows:** The disc (Z1, X1) stayed at its centre: there was nothing in it to turn. The turn moved the whole row, but the certainty was all in the correlation discs. That is what entanglement looks like in the bag.

## 4. Locked twins

Values that commute are linked through their product. If a word R has value +1, then for any word P that commutes with R, the values of P and of P times R are equal: they are locked twins (equal and opposite if R = -1). A turn whose pole commutes with R moves both twins in the same way, so the lock is kept. Only a turn whose pole anticommutes with R can loosen it. If R is loud but not at +1, the twins are tied loosely: the closer R is to +1, the tighter the tie. This is one way to make a group of values move as one, for example to share weights between symmetric parts of a neural network whose weights are values in the bag.

### Puzzle 4.1: Locked twins

Values that commute are linked through their product. Here Z2 = +1, so X1 and X1Z2 are locked twins (their product is Z2). So are Y1 and Y1Z2, and Z1 and Z1Z2. They are outlined.

Turn qubit 1 however you like: make Y1 = -1, and watch the twins.

- **Board shows:** all 15 values.
- **Start:** Z2 = +1.000, Z1 = +0.707, Z1Z2 = +0.707, X1 = +0.707, X1Z2 = +0.707.
- **Outlined:** X1, X1Z2, Y1, Y1Z2, Z1, Z1Z2.
- **Buttons:**
  1. *ry(-pi/4) on qubit 1*: turn about Y1 by -0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  2. *rx(pi/2) on qubit 1*: turn about X1 by +0.5 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, Y1, Y1Z2, Y1X2, Y1Y2. Discs: (Z1, Y1), (Z1Z2, Y1Z2), (Z1X2, Y1X2), (Z1Y2, Y1Y2).
- **Goal:** Y1 = -1 (within 0.05).
- **A solution:** buttons 1, 2. Afterwards: Z2 = +1.000, Y1 = -1.000, Y1Z2 = -1.000.
- **What it shows:** Every twin pair stayed equal, whatever you did to qubit 1. A turn whose pole commutes with Z2 moves both twins the same way.

### Puzzle 4.2: Untying

Only a turn whose pole anticommutes with Z2 can loosen the lock, and that means turning qubit 2.

Make X1Z2 = 0 while keeping X1 = 0.707.

- **Board shows:** all 15 values.
- **Start:** Z2 = +1.000, Z1 = +0.707, Z1Z2 = +0.707, X1 = +0.707, X1Z2 = +0.707.
- **Outlined:** X1, X1Z2, Y1, Y1Z2, Z1, Z1Z2.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  2. *ry(pi/4) on qubit 2*: turn about Y2 by +0.25 pi. Can move: Z2, X2, Z1Z2, Z1X2, X1Z2, X1X2, Y1Z2, Y1X2. Discs: (Z2, X2), (Z1Z2, Z1X2), (X1Z2, X1X2), (Y1Z2, Y1X2).
- **Goal:** X1 = +0.707, X1Z2 = +0 (within 0.05).
- **A solution:** buttons 2, 2. Afterwards: X2 = +1.000, Z1 = +0.707, Z1X2 = +0.707, X1 = +0.707, X1X2 = +0.707.
- **What it shows:** Turning qubit 2 moved Z2 away from +1 and the twins came apart. Halfway, with Z2 = 0.707, they were tied loosely: X1Z2 was 0.707 times X1.

## 5. Discs with correlations as poles

Any word can be a pole, including correlations such as Y1Z2. Their discs mix single-qubit values with correlations, so turns about them move certainty between single qubits and correlations. This is how gates create and remove entanglement. The familiar two-qubit gates are made of such turns: cz is a quarter turn about Z1Z2 (backwards) together with quarter turns about Z1 and Z2; cx with qubit 1 as control is the same with Z1X2, Z1 and X2.

### Puzzle 5.1: Turning entanglement off

Any word can be a pole. A turn about Y1Z2 turns the discs (Z1Z2, X1) and (X2, Y1Y2), and two more: hover to see them.

Start from the Bell state and make X1 = X2 = +1.

- **Board shows:** all 15 values.
- **Start:** Z1Z2 = +1.000, X1X2 = +1.000, Y1Y2 = -1.000.
- **Buttons:**
  1. *turn about Y1Z2*: turn about Y1Z2 by +0.25 pi. Can move: X2, Y2, Z1, Z1Z2, X1, X1Z2, Y1X2, Y1Y2. Discs: (X2, Y1Y2), (Y2, Y1X2), (Z1, X1Z2), (Z1Z2, X1).
  2. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  3. *ry(pi/4) on qubit 2*: turn about Y2 by +0.25 pi. Can move: Z2, X2, Z1Z2, Z1X2, X1Z2, X1X2, Y1Z2, Y1X2. Discs: (Z2, X2), (Z1Z2, Z1X2), (X1Z2, X1X2), (Y1Z2, Y1X2).
- **Goal:** X1 = +1, X2 = +1 (within 0.05).
- **A solution:** buttons 1, 1. Afterwards: X2 = +1.000, X1 = +1.000, X1X2 = +1.000.
- **What it shows:** The certainty moved from correlations into the single qubits: the pair is no longer entangled. X1X2 commutes with the pole, so it stayed at +1.

### Puzzle 5.2: Turning entanglement on

Start with X1 = Z2 = +1. A turn about Z1X2 has discs (X1, Y1X2) and (Z2, Z1Y2).

Make every single-qubit value 0: aim for Y1X2 = +1 and Z1Y2 = -1.

- **Board shows:** all 15 values.
- **Start:** Z2 = +1.000, X1 = +1.000, X1Z2 = +1.000.
- **Buttons:**
  1. *turn about Z1X2*: turn about Z1X2 by +0.25 pi. Can move: Z2, Y2, Z1Z2, Z1Y2, X1, X1X2, Y1, Y1X2. Discs: (Z2, Z1Y2), (Y2, Z1Z2), (X1, Y1X2), (X1X2, Y1).
  2. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
- **Goal:** Y1X2 = +1, Z1Y2 = -1 (within 0.05).
- **A solution:** buttons 1, 1. Afterwards: Z1Y2 = -1.000, X1Z2 = +1.000, Y1X2 = +1.000.
- **What it shows:** X1 moved into Y1X2 and Z2 into Z1Y2. X1Z2 commutes with the pole and stayed at +1. Now all of the budget is in correlations: the pair is fully entangled.

### Puzzle 5.3: A cz is three turns

The cz gate is three quarter turns done together: about Z1Z2 (backwards), about Z1 and about Z2.

Use them to build the cluster state from Hello Qubits: X1Z2 = Z1X2 = +1.

- **Board shows:** all 15 values.
- **Start:** X2 = +1.000, X1 = +1.000, X1X2 = +1.000.
- **Buttons:**
  1. *quarter turn back about Z1Z2*: turn about Z1Z2 by -0.5 pi. Can move: X2, Y2, Z1X2, Z1Y2, X1, X1Z2, Y1, Y1Z2. Discs: (X2, Z1Y2), (Y2, Z1X2), (X1, Y1Z2), (X1Z2, Y1).
  2. *quarter turn about Z1*: turn about Z1 by +0.5 pi. Can move: X1, X1Z2, X1X2, X1Y2, Y1, Y1Z2, Y1X2, Y1Y2. Discs: (X1, Y1), (X1Z2, Y1Z2), (X1X2, Y1X2), (X1Y2, Y1Y2).
  3. *quarter turn about Z2*: turn about Z2 by +0.5 pi. Can move: X2, Y2, Z1X2, Z1Y2, X1X2, X1Y2, Y1X2, Y1Y2. Discs: (X2, Y2), (Z1X2, Z1Y2), (X1X2, X1Y2), (Y1X2, Y1Y2).
- **Goal:** X1Z2 = +1, Z1X2 = +1 (within 0.05).
- **A solution:** buttons 1, 2, 3. Afterwards: Z1X2 = +1.000, X1Z2 = +1.000, Y1Y2 = +1.000.
- **What it shows:** The order doesn't matter, because these three poles commute. Every two-qubit gate can be described as turns, some of them about correlation poles.

## 6. Pushes (for designers)

This chapter is for people designing learning rules or other methods that treat the values as numbers to adjust. Such methods often ask for a push: make value P a little smaller, and let everything else follow however it must. A push is not a gate. It is what a learning rule asks for, and to carry it out on a device it has to be turned into turns (chapter 7) or done by expensive methods such as quantum imaginary time evolution. Target-based programming (such as the Motte model) works with turns and targets, not pushes. But pushes show clearly how the whole bag is linked. When P is pushed, each value Q moves in proportion to the covariance of P and Q, which is 1/2 <PQ + QP> - <P><Q>. It has three cases. Q is P itself: 1 - P squared (saturation: values near +1 or -1 hardly move). P and Q commute: <PQ> - <P><Q> (twins: if their product is loud, Q follows P). P and Q anticommute: -<P><Q> (discs: they compete for the disc's budget). So turns link anticommuting values, and pushes link commuting values through their products and make anticommuting values compete.

### Puzzle 6.1: Push and follow

A push is not a gate. It asks one value to change and lets the rest follow however they must. Hover over a push button: each value shows how strongly it follows (its covariance with the pushed value).

Push X1 down to -0.3.

- **Board shows:** all 15 values.
- **Start:** Z2 = +0.600, Z1 = +0.600, Z1Z2 = +1.000, X1X2 = +0.800, Y1Y2 = -0.800.
- **Buttons:**
  1. *push X1 down*: push X1 down (imaginary-time steps, total 0.05). At the start, values follow with covariance: X2 +0.80, X1 +1.00, X1Z2 +0.60.
  2. *push X1 up*: push X1 up (imaginary-time steps, total 0.05). At the start, values follow with covariance: X2 +0.80, X1 +1.00, X1Z2 +0.60.
- **Goal:** X1 = -0.3 (within 0.05).
- **A solution:** buttons 1, 1, 1. Afterwards: Z2 = +0.600, X2 = -0.233, Z1 = +0.574, Z1Z2 = +0.957, X1 = -0.292, X1Z2 = -0.175, X1X2 = +0.800, Y1Y2 = -0.765.
- **What it shows:** At the start, X2 followed at 0.8 of the rate and X1Z2 at 0.6. X1 commutes with both, and their products with X1 (X1X2 = 0.8 and Z2 = 0.6) are loud. For commuting values the covariance is <PQ> - <P><Q>.
- **More:** The start state is sqrt(0.8)|00> + sqrt(0.2)|11>: Z1 = Z2 = 0.6, Z1Z2 = 1, X1X2 = 0.8, Y1Y2 = -0.8, all else 0. X1 is 0 and anticommutes with Z1, so -<X1><Z1> = 0 and Z1 doesn't move at first.

### Puzzle 6.2: Push and compete

One qubit with X1 = Z1 = 0.707.

Push Z1 up to 0.9 and watch X1.

- **Board shows:** Z1, X1, Y1 only.
- **Start:** Z1 = +0.707, X1 = +0.707.
- **Buttons:**
  1. *push Z1 up*: push Z1 up (imaginary-time steps, total 0.15). At the start, values follow with covariance: Z1 +0.50, X1 -0.50.
- **Goal:** Z1 = +0.9 (within 0.05).
- **A solution:** buttons 1, 1, 1. Afterwards: Z1 = +0.946, X1 = +0.325.
- **What it shows:** X1 fell as Z1 rose: anticommuting values compete for their disc's budget (covariance -<P><Q>). Z1 also slowed as it neared +1: that is saturation (covariance 1 - P squared).

## 7. Getting the change you want

Usually you don't want to turn a particular disc: you want some values to change. A small turn by angle theta about a pole G moves any value Q that anticommutes with G by theta times the value of their product (up to sign). So a value can only move through a pole whose product with it is non-zero; if every available pole gives a product of 0, the value is frozen. With a limited set of poles, some changes can be reached exactly, some partly, some not at all. Target-based programming, such as the Motte model, lets you state the values you want (absolute, or relative to the current ones) and leave the others free; the device finds the closest change it can make with the turns it has.

### Puzzle 7.1: Frozen

A small turn about a pole moves a value by the value of their product. In a Bell state every single-qubit value is 0, so turns on one qubit have nothing to work with.

Make X1 = 0.707.

- **Board shows:** all 15 values.
- **Start:** Z1Z2 = +1.000, X1X2 = +1.000, Y1Y2 = -1.000.
- **Buttons:**
  1. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  2. *rx(pi/4) on qubit 1*: turn about X1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, Y1, Y1Z2, Y1X2, Y1Y2. Discs: (Z1, Y1), (Z1Z2, Y1Z2), (Z1X2, Y1X2), (Z1Y2, Y1Y2).
  3. *ry(pi/4) on qubit 2*: turn about Y2 by +0.25 pi. Can move: Z2, X2, Z1Z2, Z1X2, X1Z2, X1X2, Y1Z2, Y1X2. Discs: (Z2, X2), (Z1Z2, Z1X2), (X1Z2, X1X2), (Y1Z2, Y1X2).
  4. *rx(pi/4) on qubit 2*: turn about X2 by +0.25 pi. Can move: Z2, Y2, Z1Z2, Z1Y2, X1Z2, X1Y2, Y1Z2, Y1Y2. Discs: (Z2, Y2), (Z1Z2, Z1Y2), (X1Z2, X1Y2), (Y1Z2, Y1Y2).
  5. *turn about Y1Z2*: turn about Y1Z2 by +0.25 pi. Can move: X2, Y2, Z1, Z1Z2, X1, X1Z2, Y1X2, Y1Y2. Discs: (X2, Y1Y2), (Y2, Y1X2), (Z1, X1Z2), (Z1Z2, X1).
- **Goal:** X1 = +0.707 (within 0.05).
- **A solution:** buttons 5. Afterwards: X2 = +0.707, Z1Z2 = +0.707, X1 = +0.707, X1X2 = +1.000, Y1Y2 = -0.707.
- **What it shows:** Only the turn about Y1Z2 could do it: its product with X1 is Z1Z2, which is +1. Poles on qubit 1 give products that are single-qubit values (all 0 here), and poles on qubit 2 commute with X1.

### Puzzle 7.2: Asking for a change

Instead of choosing turns, you can state a target and let the device find the turns. Each button asks for X1 to rise by 0.25, leaving every other value free. They differ in which poles the device may use.

Reach X1 = 0.5.

- **Board shows:** all 15 values.
- **Start:** Z1Z2 = +1.000, X1X2 = +1.000, Y1Y2 = -1.000.
- **Buttons:**
  1. *X1 up 0.25: turns on single qubits*: target: change X1 by +0.25, others free; the device may turn about X1, Y1, Z1, X2, Y2, Z2.
  2. *X1 up 0.25: also Y1Z2*: target: change X1 by +0.25, others free; the device may turn about X1, Y1, Z1, X2, Y2, Z2, Y1Z2.
- **Goal:** X1 = +0.5 (within 0.05).
- **A solution:** buttons 2, 2. Afterwards: X2 = +0.497, Z1Z2 = +0.868, X1 = +0.497, X1X2 = +1.000, Y1Y2 = -0.868.
- **What it shows:** With single-qubit poles the device could do nothing, because X1 was frozen. With Y1Z2 allowed it found a turn. This is the idea behind target-based quantum programming, such as the Motte model: say what values you want and which turns are allowed, and let the device work out the gates.

### Puzzle 7.3: Sandbox

All the turns from this tutorial, to play with. Hover over a button to see its discs.

That's the end of the tutorial. Press Menu to go back.

- **Board shows:** all 15 values.
- **Start:** Z2 = +1.000, Z1 = +1.000, Z1Z2 = +1.000.
- **Buttons:**
  1. *h on qubit 1*: turn about (X1 + Z1)/sqrt2 by +1 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2, Y1, Y1Z2, Y1X2, Y1Y2.
  2. *h on qubit 2*: turn about (X2 + Z2)/sqrt2 by +1 pi. Can move: Z2, X2, Y2, Z1Z2, Z1X2, Z1Y2, X1Z2, X1X2, X1Y2, Y1Z2, Y1X2, Y1Y2.
  3. *ry(pi/4) on qubit 1*: turn about Y1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2. Discs: (Z1, X1), (Z1Z2, X1Z2), (Z1X2, X1X2), (Z1Y2, X1Y2).
  4. *ry(pi/4) on qubit 2*: turn about Y2 by +0.25 pi. Can move: Z2, X2, Z1Z2, Z1X2, X1Z2, X1X2, Y1Z2, Y1X2. Discs: (Z2, X2), (Z1Z2, Z1X2), (X1Z2, X1X2), (Y1Z2, Y1X2).
  5. *rx(pi/4) on qubit 1*: turn about X1 by +0.25 pi. Can move: Z1, Z1Z2, Z1X2, Z1Y2, Y1, Y1Z2, Y1X2, Y1Y2. Discs: (Z1, Y1), (Z1Z2, Y1Z2), (Z1X2, Y1X2), (Z1Y2, Y1Y2).
  6. *rx(pi/4) on qubit 2*: turn about X2 by +0.25 pi. Can move: Z2, Y2, Z1Z2, Z1Y2, X1Z2, X1Y2, Y1Z2, Y1Y2. Discs: (Z2, Y2), (Z1Z2, Z1Y2), (X1Z2, X1Y2), (Y1Z2, Y1Y2).
  7. *turn about Y1Z2*: turn about Y1Z2 by +0.25 pi. Can move: X2, Y2, Z1, Z1Z2, X1, X1Z2, Y1X2, Y1Y2. Discs: (X2, Y1Y2), (Y2, Y1X2), (Z1, X1Z2), (Z1Z2, X1).
  8. *turn about Z1X2*: turn about Z1X2 by +0.25 pi. Can move: Z2, Y2, Z1Z2, Z1Y2, X1, X1X2, Y1, Y1X2. Discs: (Z2, Z1Y2), (Y2, Z1Z2), (X1, Y1X2), (X1X2, Y1).
  9. *cz*: turn about Z1Z2 by -0.5 pi and turn about Z1 by +0.5 pi and turn about Z2 by +0.5 pi. Can move: X2, Y2, Z1X2, Z1Y2, X1, X1Z2, X1X2, X1Y2, Y1, Y1Z2, Y1X2, Y1Y2.
  10. *push X1 down*: push X1 down (imaginary-time steps, total 0.05). At the start, values follow with covariance: X1 +1.00, X1Z2 +1.00.
- **Goal:** none, explore.

## Summary

1. Two values that **anticommute** (odd count) form a **disc**, and their product is its **pole**.
2. A turn turns **every disc with its pole** at once. A turn only touches words that overlap its pole.
3. The squares of all values add up to a fixed **budget**. A disc's radius shows how much of it is there; a loud pole squeezes its discs. Entanglement moves certainty from single-qubit discs into correlation discs. Values at +1 or -1 are **saturated**.
4. Values that **commute** are linked through their product: if it is loud, they are **locked twins**.
5. Turns about **correlation poles** move certainty between single qubits and correlations.
6. **Pushes** (for learning rules) link commuting values through their products and make anticommuting values compete.
7. What you can change depends on which **poles** you can turn about. Targets let the device find the turns.
