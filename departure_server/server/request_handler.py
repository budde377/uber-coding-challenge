import json
from urllib.parse import urlparse, parse_qs
from departure_server.server.rest import RESTHandler, NoSuchFunctionException

__author__ = 'budde'

import http.server

_rest_handler = RESTHandler()


class CustomRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, request, client_address, server):
        super().__init__(request, client_address, server)

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
        try:
            self.send_result(_rest_handler.handle(path, query))
            
        except NoSuchFunctionException:
            self.send_error(400, "Bad request")

    def send_result(self, result):
        """
        Sends the provided results with status code 200
        :param result: string
        :return: void
        """
        formatted_result = json.dumps(result)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(bytes(formatted_result,'UTF-8'))


