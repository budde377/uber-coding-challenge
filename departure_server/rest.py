from departure_server.query_strategy import QueryStrategy
from departure_server.station import StationLibrary, Position

__author__ = 'budde'


class NoSuchFunctionException(Exception):
    def __init__(self, key):
        self.key = key


class Handler:
    def __init__(self, name=None):
        self.name = name
        self.functions = {}
        self.handlers = {}

    def add_function(self, name: str, function):
        """
        Adds a function to a corresponding function name
        :param name: The function name
        :param function: A function taking two positional parameters: Name and input
        :return:
        """
        self.functions[name] = function

    def add_handler(self, name: str):
        """
        If a handler hasn't been added, a new handler is created. A function is also
        added in order to mimic a recursive call to handle.
        If a handler has previously been addend, that instance is returned.
        :param name: The name for the handler
        :return: A handler
        """
        if name in self.handlers:
            return self.handlers[name]
        self.handlers[name] = handler = Handler(name)
        self.add_function(name, lambda nme, inp: handler.handle(nme[1:], inp))
        return handler

    def handle(self, name: list, handler_input: dict=None):
        """
        Resolves the right name and calls the appropriate function.
        If no function is found an NoSuchFunctionException will be thrown
        :param name: A list of names
        :param handler_input: The input passed to the *last* function
        :return:
        """
        if len(name) == 0:
            raise NoSuchFunctionException("")
        handler_input = {} if handler_input is None else handler_input
        function_name = name[0] if name[0] in self.functions else "*"
        if function_name not in self.functions:
            raise NoSuchFunctionException(name[0])
        return (self.functions[function_name])(name, handler_input)


class RESTHandler(Handler):
    def __init__(self, query_strategy: QueryStrategy):
        super().__init__(None)
        self.library = StationLibrary(query_strategy)
        self.setup_v1_0()

    def setup_v1_0(self):
        """
        Sets up v1.0 of the API
        :return:
        """
        handler = self.add_handler('1.0')
        site_library_handler = handler.add_handler('StationLibrary')
        site_library_handler.add_function('findNearby',
                                          lambda name, inp: self.library.find_nearby(
                                              Position(int(inp['lat']), int(inp['long'])),
                                              int(inp['radius'])))
        site_library_handler.add_function('stationFromName',
                                          lambda name, inp: self.library.station_from_name(inp['name']))
