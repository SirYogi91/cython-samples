# cython: language_level=3
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

import sys

cdef struct BoardPosition:
    int row
    int column

cdef class State:

    cdef int **board
    cdef BoardPosition _zero_index
    cdef State parent

    @classmethod
    def from_file(cls, data):
        cdef int index, ondex
        cdef State retval
        retval = State()
        for index, line in enumerate(data.split('\n')):
            if not line:
                continue
            numbers = [int(x) if x != 'X' else 0 for x in line.split()]
            for ondex in range(3):
                retval.board[index][ondex] = numbers[ondex]
        retval.parent = None
        return retval

    def __cinit__(self):
        cdef int index
        self.board = <int **>malloc(3*sizeof(int*))
        for index in range(3):
            self.board[index] = <int *>malloc(3*sizeof(int))
        self._zero_index.row = -1

    def __str__(self):
        parts = []
        for x in range(3):
            row = self.board[x]
            parts.append(' '.join([str(row[y]) for y in range(3)]))
        return "\n".join(parts)

    cdef BoardPosition zero_index(self):
        cdef int i, j
        if self._zero_index.row != -1:
            return self._zero_index
        for i in range(3):
            for j in range(3):
                if self.board[i][j] == 0:
                    self._zero_index = BoardPosition(i, j)
                    return self._zero_index
        raise ValueError("Invalid board")


    cdef set_board(self, int **parent_board, BoardPosition zero_pos, BoardPosition swap):
        cdef int index
        for index in range(3):
            memcpy(self.board[index], parent_board[index], 3*sizeof(int))
        self.board[zero_pos.row][zero_pos.column] = self.board[swap.row][swap.column]
        self.board[swap.row][swap.column] = 0


    cpdef children(self):
        cdef BoardPosition zi = self.zero_index()
        cdef BoardPosition *swaps = <BoardPosition *>malloc(4*sizeof(BoardPosition))
        cdef int swaps_counter = 0, index = 0
        cdef State child
        #cdef PyObject **children
        #left
        if zi.column > 0:
            swaps[swaps_counter] = BoardPosition(zi.row, zi.column - 1)
            swaps_counter += 1
        #right
        if zi.column < 2:
            swaps[swaps_counter] = BoardPosition(zi.row, zi.column + 1)
            swaps_counter += 1
        #above
        if zi.row > 0:
            swaps[swaps_counter] = BoardPosition(zi.row - 1, zi.column)
            swaps_counter += 1
        #below
        if zi.row < 2:
            swaps[swaps_counter] = BoardPosition(zi.row + 1, zi.column)
            swaps_counter += 1
        #children = <PyObject **>malloc(swaps_counter*sizeof(PyObject *))
        children = []
        for index in range(swaps_counter):
            child = State()
            child.set_board(self.board, zi, swaps[index])
            children.append(child)
        return children

if __name__ == "__main__":
    with open (sys.argv[1], 'r') as inp_file:
        data = inp_file.read()
    state = State.from_file(data)
    children = state.children()
    print(children[0])