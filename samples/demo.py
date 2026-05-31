"""Demo Python module for Emacs verification."""

from dataclasses import dataclass
from typing import Iterator


@dataclass
class Point:
    x: float
    y: float

    def distance(self, other: "Point") -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5


def fibonacci(n: int) -> Iterator[int]:
    """Generate Fibonacci sequence up to n terms."""
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b


def main() -> None:
    # TODO: Add argument parsing
    points = [Point(i, i**2) for i in range(5)]

    for i, p in enumerate(points[:-1]):
        d = p.distance(points[i + 1])
        print(f"{p} -> {points[i + 1]}: distance = {d:.2f}")

    # FIXME: Handle edge case when n <= 0
    fibs = list(fibonacci(10))
    print(f"Fibonacci: {fibs}")


if __name__ == "__main__":
    main()
