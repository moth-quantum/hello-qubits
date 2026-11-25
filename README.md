# Hello Qubits

A Godot 4 port of the *Hello Qiskit* puzzle game from the [Qiskit Textbook](https://github.com/Qiskit/textbook), released here as *Hello Qubits*.

*Hello Qiskit* is a sister project of [Hello Quantum](https://helloquantum.mybluemix.net/), the quantum puzzle app developed by the University of Basel and IBM. Both games teach quantum computing through a visual representation of two-qubit states as Pauli expectation values arranged in a diamond lattice. Each puzzle asks the player to transform the state using quantum gates — X, Z, H, CNOT, and CZ — until the displayed values match a target configuration.

## Interdependency tutorial

Choose *Interdependency tutorial* on the title screen. It carries on where the puzzles stop, in the spirit of Hello Qiskit's Level 4 (non-Clifford gates and Bloch mode), and shows how the 15 values of two qubits depend on each other: discs and their poles, one turn moving many discs, the budget shared by all values, locked twins, discs with correlation poles, pushes (for people designing learning rules) and targets.

- `tutorial/tutorial.json` holds all the content. The game reads it, and `tools/build_tutorial.py` turns it into [TUTORIAL.md](TUTORIAL.md), the same tutorial written out for reading, teaching or use by AI models.
- `tools/tutorial_engine.py` (Python, numpy) and `pauli2.gd` (GDScript) are the same two-qubit engine. `python3 tools/build_tutorial.py --check` replays every puzzle's solution in Python; `Godot --headless --path . res://tutorial.tscn -- --test` does the same in the game.
- After editing the JSON, run `python3 tools/build_tutorial.py` to recheck and regenerate TUTORIAL.md.

## Quantum engine

Gate simulation uses [MicroMoth](https://github.com/moth-quantum/MicroMoth), a lightweight statevector simulator written in GDScript.

## Licence

This project is licensed under the [Apache License 2.0](LICENSE), consistent with the original Hello Qiskit source.
