"""Check every tutorial puzzle and write TUTORIAL.md from tutorial/tutorial.json.

    python3 tools/build_tutorial.py          # check, then write TUTORIAL.md
    python3 tools/build_tutorial.py --check  # check only, print details

Checks: the goal is not met at the start, the stated solution meets it, and (for puzzles with only
gate and turn buttons) the shortest solution found by search.
"""
import json, sys, os
from collections import deque
import numpy as np
from tutorial_engine import State, WORDS, name, discs, anticommute, expand

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOL = 0.05


def start_state(p):
    s = State()
    for a in p['start']:
        s.apply(a)
    return s


def met(s, goal):
    return bool(goal) and all(abs(s.value(w) - v) <= TOL for w, v in goal.items())


def shortest(p, depth=9):
    if not p['goal'] or any('push' in b or 'target' in b for b in p['buttons']):
        return None
    s0 = start_state(p)
    seen = {}
    q = deque([(s0.psi, [])])
    while q:
        psi, path = q.popleft()
        s = State(); s.psi = psi
        if met(s, p['goal']):
            return path
        if len(path) >= depth:
            continue
        for i, b in enumerate(p['buttons']):
            t = State(); t.psi = psi.copy(); t.apply(b)
            key = tuple(np.round(list(t.values().values()), 3))
            if key in seen:
                continue
            seen[key] = 1
            q.append((t.psi, path + [i]))
    return 'unreachable'


def fmt_values(s, words=None):
    words = words or WORDS
    items = [f"{name(w)} = {s.value(w):+.3f}".replace('+0.000', '0').replace('-0.000', '0') for w in words
             if abs(s.value(w)) > 5e-4]
    return ', '.join(items) if items else 'all 0'


def button_text(b):
    if 'push' in b:
        d = 'down' if b.get('sign', 1) > 0 else 'up'
        return f"push {name(b['push'])} {d} (imaginary-time steps, total {b.get('amount', 0.1)})"
    if 'target' in b:
        ch = ', '.join(f"{name(w)} by {d:+g}" for w, d in b['target'].items())
        return f"target: change {ch}, others free; the device may turn about {', '.join(name(g) for g in b['poles'])}"
    parts = []
    for pole, ang in expand(b):
        pn = name(pole) if isinstance(pole, str) else '(' + ' + '.join(name(k) for k in pole) + ')/sqrt2'
        parts.append(f"turn about {pn} by {ang / np.pi:+g} pi")
    return ' and '.join(parts)


def moved(b):
    """Words a gate/turn button can move (those anticommuting with one of its poles)."""
    if 'push' in b or 'target' in b:
        return []
    out = set()
    for pole, _ in expand(b):
        ws = [pole] if isinstance(pole, str) else list(pole)
        for w in WORDS:
            if any(anticommute(w, g) for g in ws):
                out.add(w)
    return [w for w in WORDS if w in out]


def check(verbose):
    data = json.load(open(os.path.join(ROOT, 'tutorial', 'tutorial.json')))
    ok = True
    for ci, ch in enumerate(data['chapters']):
        for pi, p in enumerate(ch['puzzles']):
            s = start_state(p)
            tag = f"{ch['title']} / {p['title']}"
            if met(s, p['goal']):
                print('GOAL MET AT START:', tag); ok = False
            for i in p['solution']:
                s.apply(p['buttons'][i])
            if p['goal'] and not met(s, p['goal']):
                print('SOLUTION FAILS:', tag, fmt_values(s)); ok = False
            if verbose:
                print(f"\n== {tag}\n start: {fmt_values(start_state(p))}\n after solution: {fmt_values(s)}")
                sh = shortest(p)
                if sh is not None:
                    print(' shortest:', sh, '' if sh == 'unreachable' or len(sh) == len(p['solution']) else '  (differs in length from stated)')
    return data, ok


def write_md(data):
    L = []
    L.append(f"# {data['title']}\n")
    L.append("*An interactive tutorial in Hello Qubits, written out in full so that it can be read, taught or "
             "followed without the game, by people or by AI models.*\n")
    L.append(data['intro'] + "\n")
    L.append("""## How to use this file

- **Playing the game:** run Hello Qubits and choose *Interdependency tutorial* on the title screen. Each puzzle below is one screen.
- **Reading it:** each puzzle gives the starting values, the buttons and exactly what each does, the goal, a solution, and what it shows. Every number here was produced by the simulator in `tools/tutorial_engine.py`, which does exactly what the game does.
- **Teaching from it (people or AI tutors):** take one puzzle at a time. Before revealing what happens, ask the learner to predict it. Don't invent numbers: compute them with `tools/tutorial_engine.py` (needs only numpy), or use the ones given here.

## Conventions

- Two qubits, called qubit 1 and qubit 2.
- A value is a number from -1 to +1. In the game: black circle +1, white circle -1, grey 0.
- Values are written with the qubit number after each letter: X1 is X on qubit 1, Z1Z2 is the correlation of the Z outputs of both qubits, Y1X2 is Y on qubit 1 with X on qubit 2. (In code, `tools/tutorial_engine.py` writes these as two-letter strings, first letter qubit 1: `XI`, `ZZ`, `YX`.)
- A **turn about a pole** G by angle theta applies exp(-i theta G / 2). For example ry(theta) on qubit 1 is a turn about Y1 by theta, and rx(theta) is a turn about X1.
- The game board is the diamond from Hello Qubits, extended with the Y values: qubit 1's own values (Z1, X1, Y1) run down the left edge, qubit 2's down the right edge, and each correlation sits where its two rows meet.
""")
    for ci, ch in enumerate(data['chapters']):
        L.append(f"## {ch['title']}\n")
        L.append(ch['concept'] + "\n")
        for pi, p in enumerate(ch['puzzles']):
            s = start_state(p)
            L.append(f"### Puzzle {ci}.{pi + 1}: {p['title']}\n")
            L.append(p['text'].replace('\n\n', '\n\n') + "\n")
            vis = WORDS if p['visible'] == 'all' else p['visible']
            shown = 'all 15 values' if p['visible'] == 'all' else ', '.join(name(w) for w in vis) + ' only'
            L.append(f"- **Board shows:** {shown}.")
            L.append(f"- **Start:** {fmt_values(s, vis)}" + ("" if p['visible'] == 'all' else "") + ".")
            if p.get('highlight'):
                L.append(f"- **Outlined:** {', '.join(name(w) for w in p['highlight'])}.")
            L.append("- **Buttons:**")
            for i, b in enumerate(p['buttons']):
                line = f"  {i + 1}. *{b['label']}*: {button_text(b)}."
                mv = [w for w in moved(b) if w in vis]
                if mv:
                    line += f" Can move: {', '.join(name(w) for w in mv)}."
                single = [pole for pole, _ in expand(b)] if not ('push' in b or 'target' in b) else []
                if len(single) == 1 and isinstance(single[0], str):
                    ds = [d for d in discs(single[0]) if d[0] in vis or d[1] in vis]
                    line += f" Discs: {', '.join('(' + name(a) + ', ' + name(c) + ')' for a, c in ds)}."
                if 'push' in b:
                    cov = [(w, s.covariance(b['push'], w)) for w in vis]
                    line += " At the start, values follow with covariance: " + ', '.join(
                        f"{name(w)} {c:+.2f}" for w, c in cov if abs(c) > 5e-3) + "."
                L.append(line)
            if p['goal']:
                L.append(f"- **Goal:** {', '.join(f'{name(w)} = {v:+g}' for w, v in p['goal'].items())} (within {TOL}).")
                t = start_state(p)
                for i in p['solution']:
                    t.apply(p['buttons'][i])
                sol = ', '.join(str(i + 1) for i in p['solution'])
                L.append(f"- **A solution:** buttons {sol}. Afterwards: {fmt_values(t, vis)}.")
            else:
                L.append("- **Goal:** none, explore.")
            if p.get('after'):
                L.append(f"- **What it shows:** {p['after']}")
            if p.get('notes'):
                L.append(f"- **More:** {p['notes']}")
            L.append("")
    L.append("""## Summary

1. Two values that **anticommute** (odd count) form a **disc**, and their product is its **pole**.
2. A turn turns **every disc with its pole** at once. A turn only touches words that overlap its pole.
3. The squares of all values add up to a fixed **budget**. A disc's radius shows how much of it is there; a loud pole squeezes its discs. Entanglement moves certainty from single-qubit discs into correlation discs. Values at +1 or -1 are **saturated**.
4. Values that **commute** are linked through their product: if it is loud, they are **locked twins**.
5. Turns about **correlation poles** move certainty between single qubits and correlations.
6. **Pushes** (for learning rules) link commuting values through their products and make anticommuting values compete.
7. What you can change depends on which **poles** you can turn about. Targets let the device find the turns.
""")
    open(os.path.join(ROOT, 'TUTORIAL.md'), 'w').write('\n'.join(L))


if __name__ == '__main__':
    verbose = '--check' in sys.argv
    data, ok = check(verbose)
    print('all puzzles OK' if ok else 'PROBLEMS FOUND')
    if ok and not verbose:
        write_md(data)
        print('wrote TUTORIAL.md')
