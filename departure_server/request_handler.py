import json
from urllib.parse import urlparse, parse_qs

from departure_server.query_strategy import QueryStrategy
from departure_server.station import Station, Position, Departure
from departure_server.rest import RESTHandler, NoSuchFunctionException

__author__ = 'budde'

import http.server


def setup_handler(strategy: QueryStrategy):
    handler = CustomRequestHandler
    handler.__REST_HANDLER__ = RESTHandler(strategy)
    return handler


class ModelEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Station):
            return {'id': o.id, 'name': o.name, 'pos': self.default(o.pos)}

        if isinstance(o, Position):
            return {'long': o.long, 'lat': o.lat}

        if isinstance(o, Departure):
            return {
                'name': o.name,
                'date': o.date.timestamp(),
                'departure_type': o.departure_type,
                'direction': o.direction
            }

        return super().default(o)


class CustomRequestHandler(http.server.SimpleHTTPRequestHandler):
    __REST_HANDLER__ = None

    def list_directory(self, path):
        """
        Will send a 404. Listing of dictionaries is not allowed.
        :param path:
        :return:
        """
        self.send_error(404, "File not found")

    def do_GET(self):
        """
        Decides whether the request should be handled as an API call or
        regular server call (handled by the parent class)
        :return:
        """
        if self.path[0:5] == "/api/":
            self.send_api()
            return

        super().do_GET()

    def send_api(self):
        """
        Will handle the query as a API call.
        If the function is not found, an error 400 will be sent.
        Else JSON encoded result will be sent
        :return:
        """
        parsed_path = urlparse(self.path)
        path = parsed_path.path[1:].split("/")[1:]
        query = parse_qs(parsed_path.query)
        for key in query:
            query[key] = query[key][0]
        try:
            self.send_result(self.__REST_HANDLER__.handle(path, query))

        except NoSuchFunctionException:
            self.send_error(400, "Bad request")

    def send_result(self, result):
        """
        Sends the provided results with status code 200
        :param result: string
        :return: void
        """
        formatted_result = json.dumps(result, cls=ModelEncoder)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(bytes(formatted_result, 'UTF-8'))
