#!/usr/bin/env python3
"""Builds data/maps/arena.txt (combat test gauntlet) from a height profile.
Each segment: (columns, height in tiles, top shape or None, material).
Shapes: '/' '\\' 45 deg; '1','2' gentle rise halves; '3','4' gentle fall halves."""
H = 24
cols = []
def add(n, h, top=None, mat='x'):
    cols.extend([(h, top, mat)] * n)
def rise(h, mat='x'): add(1, h, '1', mat); add(1, h, '2', mat)
def fall(h, mat='x'): add(1, h, '3', mat); add(1, h, '4', mat)

add(3, 14, None, 'r'); add(4, 8, None, 'r'); add(1, 8, '\\', 'r'); add(1, 7, '\\', 'r'); add(1, 6, '\\', 'r'); fall(5, 'r')
add(12, 4)                                   # start
rise(5); add(4, 5); fall(5)                  # small mound
add(16, 4)                                   # encounter A: hounds
add(1, 5, '/'); add(1, 6, '/'); add(6, 6)    # hill
add(1, 6, '\\'); fall(5); add(8, 4)
add(12, 4)                                   # encounter B ground: raider
add(2, 6, None, 'r'); add(8, 7, None, 'r')   # rock ledge: hexer on top
add(1, 7, '\\', 'r'); add(1, 6, '\\', 'r'); fall(5, 'r'); add(6, 4)
rise(5); rise(6); add(8, 6)                  # encounter C mound: knot
fall(6); fall(5); add(10, 4)
add(2, 7, None, 'r'); add(22, 4); add(2, 7, None, 'r')  # encounter D: sentinel pit
add(4, 4); add(3, 14, None, 'r')
W = len(cols)
g = [['.'] * W for _ in range(H)]
for c, (h, top, mat) in enumerate(cols):
    for r in range(H - h, H):
        g[r][c] = mat
    if top:
        g[H - h][c] = top
def spawn(c, ch):
    g[H - cols[c][0] - 1][c] = ch
spawn(20, 'P')
spawn(40, 'h'); spawn(47, 'h')
spawn(74, 's'); spawn(84, 'c')
spawn(110, 'k'); spawn(118, 'h')
spawn(141, 'n')
open('data/maps/arena.txt', 'w').write('\n'.join(''.join(r) for r in g) + '\n')
print(W, 'columns')
