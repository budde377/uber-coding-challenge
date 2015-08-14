import sys

__author__ = 'budde'


class Process:
    def __init__(self, message, callback, upper_bound: int):
        self.upper_bound = upper_bound
        self.counter = 0
        self.callback = callback
        self.message = message

    def __add__(self, other):
        self.counter += other
        self.callback(self)
        return self

    def __str__(self):
        return "%s\t(%d/%d)" % (self.message, self.counter, self.upper_bound)


class Printer:
    current_process = None
    first = True
    stream = sys.stdout

    @staticmethod
    def print(message: str, upper_bound=None):
        Printer.current_process = None
        if Printer.first:
            Printer.first = False
        else:
            Printer.stream.write("\n")
        if upper_bound is None:
            Printer.stream.write(message)
            Printer.stream.flush()
            return
        process = Process(message, Printer._print_process, upper_bound)
        Printer.current_process = process
        Printer._print_process(process)
        return Printer.current_process

    @staticmethod
    def _print_process(process):
        if process != Printer.current_process:
            Printer.stream.write("\n")
            Printer.current_process = process
        Printer.stream.write("\r")
        Printer.stream.write(str(process))
        Printer.stream.flush()
