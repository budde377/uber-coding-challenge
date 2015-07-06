__author__ = 'budde'

import http.server

import departure_server.server.request_handler


if __name__ == "__main__":
    server = http.server.HTTPServer(('127.0.0.1', 8000), departure_server.server.request_handler.CustomRequestHandler)
    server.serve_forever()

