import os
import sys

class Statement():
    def __init__(self, reference: tuple):
        self.reference = reference
        self.tokens = []


class PreprocessedFile():
    def __init__(self):
        self.files = {}
        self.macros = {}
        self.defines = {}

        self.result = []

    # A reference to a particular line in a file.
    def reference(self, filename: str, line: int) -> tuple:
        return (line, filename, self.files[filename][line])
    
    # Read a file and insert it into the final output.
    def include(self, filename):
        # Read into the buffer.
        with open(filename, "r") as sf:
            self.files[filename] = sf.read().splitlines()

        # Then process. (My poor cyclomatic complexity.)
        for line in range(self.files[filename]):
            # Let the statement tokenize itself.
            statement = Statement(self.reference(filename, line))

            # Replace defines.
            for token in statement.tokens:
                for defrule in self.defines:
                    
