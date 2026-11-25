"""Reference engine for the Hello Qubits interdependency tutorial.

It does exactly what the game does, so the tutorial can be checked, and followed, without the game.

Conventions
- Two qubits, called qubit 1 and qubit 2.
- A Pauli word is two letters from I, X, Y, Z. The first letter is qubit 1, the second is qubit 2.
  So "XZ" is X on qubit 1 and Z on qubit 2, written X1Z2 in the text.
- A value is the expectation value of a word: +1 means certain to output 0, -1 certain to output 1.
- A turn about a pole G by angle theta applies exp(-i theta G / 2). The pole can be a word, or a
  normalised sum of anticommuting words (as for the h gate). ry(theta) is a turn about Y by theta.
- A push along word W with sign s lowers <s W> by imaginary-time steps psi -> psi - eps (H - <H>) psi.
- A target asks for some values to change by given amounts, and finds small turns about the allowed
  poles that do it, leaving all other values free.
"""
import numpy as np
from itertools import product

PAULI = {'I': np.eye(2, dtype=complex), 'X': np.array([[0, 1], [1, 0]], dtype=complex),
         'Y': np.array([[0, -1j], [1j, 0]], dtype=complex), 'Z': np.diag([1, -1]).astype(complex)}
WORDS = [a + b for a, b in product('IZXY', repeat=2)][1:]   # the 15 values


def word_matrix(word):
    return np.kron(PAULI[word[0]], PAULI[word[1]])


def pole_matrix(pole):
    """A pole is a word, or a dict {word: weight}."""
    if isinstance(pole, str):
        return word_matrix(pole)
    return sum(w * word_matrix(k) for k, w in pole.items())


def name(word):
    """'XZ' -> 'X1Z2', 'IY' -> 'Y2'."""
    return ''.join(l + str(i + 1) for i, l in enumerate(word) if l != 'I')


def anticommute(a, b):
    return sum(1 for x, y in zip(a, b) if x != 'I' and y != 'I' and x != y) % 2 == 1


def product_word(a, b):
    """Letter-wise product, ignoring the sign."""
    out = ''
    for x, y in zip(a, b):
        if x == 'I': out += y
        elif y == 'I' or x == y: out += 'I' if x == y else x
        else: out += ({'X', 'Y', 'Z'} - {x, y}).pop()
    return out


def discs(pole):
    """The discs turned by a pole that is a single word: pairs (P, Q) with Q = pole * P."""
    out = []
    for p in WORDS:
        if anticommute(p, pole):
            q = product_word(pole, p)
            pair = tuple(sorted((p, q), key=WORDS.index))
            if pair not in out:
                out.append(pair)
    return out


# Gate library: every gate is a list of commuting turns, applied together.
def expand(action):
    if 'turn' in action:
        return [(t['pole'], np.pi * t.get('angle_pi', 0) + t.get('angle', 0)) for t in action['turn']]
    g = action['gate']
    q = action.get('qubit', 1)
    one = lambda l: l + 'I' if q == 1 else 'I' + l
    th = np.pi * action.get('angle_pi', 0) + action.get('angle', 0)
    return {
        'x': [(one('X'), np.pi)], 'y': [(one('Y'), np.pi)], 'z': [(one('Z'), np.pi)],
        'h': [({one('X'): 2 ** -0.5, one('Z'): 2 ** -0.5}, np.pi)],
        'rx': [(one('X'), th)], 'ry': [(one('Y'), th)], 'rz': [(one('Z'), th)],
        'cz': [('ZZ', -np.pi / 2), ('ZI', np.pi / 2), ('IZ', np.pi / 2)],
        'cx': [('ZX', -np.pi / 2), ('ZI', np.pi / 2), ('IX', np.pi / 2)],   # control qubit 1, target qubit 2
    }[g]


class State:
    def __init__(self):
        self.psi = np.array([1, 0, 0, 0], dtype=complex)

    def value(self, word):
        return float(np.real(np.vdot(self.psi, word_matrix(word) @ self.psi)))

    def values(self):
        return {w: self.value(w) for w in WORDS}

    def turn(self, pole, angle):
        g = pole_matrix(pole)
        assert np.allclose(g @ g, np.eye(4)), "pole must square to the identity"
        self.psi = np.cos(angle / 2) * self.psi - 1j * np.sin(angle / 2) * (g @ self.psi)

    def push(self, word, sign, amount, step=0.01):
        h = sign * word_matrix(word)
        for _ in range(int(round(amount / step))):
            e = np.real(np.vdot(self.psi, h @ self.psi))
            self.psi = self.psi - step * (h @ self.psi - e * self.psi)
            self.psi /= np.linalg.norm(self.psi)

    def covariance(self, p, q):
        """How much q moves (per unit) when p is pushed: 1/2 <{P,Q}> - <P><Q>."""
        P, Q = word_matrix(p), word_matrix(q)
        anti = 0.5 * np.real(np.vdot(self.psi, (P @ Q + Q @ P) @ self.psi))
        return anti - self.value(p) * self.value(q)

    def rate(self, pole, q):
        """d<Q>/d theta for a small turn about a word pole: -Im <psi| G Q |psi>."""
        return -float(np.imag(np.vdot(self.psi, word_matrix(pole) @ word_matrix(q) @ self.psi)))

    def target(self, change, poles, iters=200, max_step=0.05, tol=0.01):
        """Relative target: move the listed values by the given amounts, others free."""
        goal = {w: float(np.clip(self.value(w) + d, -1, 1)) for w, d in change.items()}
        words = list(goal)
        for _ in range(iters):
            r = np.array([goal[w] - self.value(w) for w in words])
            if np.linalg.norm(r) < tol:
                break
            J = np.array([[self.rate(g, w) for g in poles] for w in words])
            th = np.linalg.solve(J.T @ J + 1e-3 * np.eye(len(poles)), J.T @ r)
            if np.max(np.abs(th)) < 1e-6:
                break
            th *= min(1.0, max_step / np.max(np.abs(th)))
            for g, t in zip(poles, th):
                self.turn(g, t)
        return goal

    def apply(self, action):
        if 'push' in action:
            self.push(action['push'], action.get('sign', 1), action.get('amount', 0.1))
        elif 'target' in action:
            self.target(action['target'], action['poles'])
        else:
            for pole, angle in expand(action):
                self.turn(pole, angle)
