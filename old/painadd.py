
def nand(a, b):
    return (~((a & 0xFF) & (b & 0xFF))) & 0xFF

def step_pain(a, b, c):
    n1 = nand(a, b)
    n2 = nand(a, n1)
    n3 = nand(b, n1)
    n4 = nand(n2, n3)
    n5 = nand(n4, c)
    n6 = nand(n4, n5)
    n7 = nand(n5, c)
    n8 = nand(n6, n7)
    nc = nand(n5, n1)
    return (n8, nc)

def do_add(a, b):
    na, nb = step_pain(a, b, 0)
    xa, xb = step_pain(a, b, nb)
    fa, fb = step_pain(xa, xb, 0)
    return fa
