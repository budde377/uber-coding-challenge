import sys

from departure_server.query_strategy import RejseplanenQueryStrategy
import departure_server.request_handler

__author__ = 'budde'

import http.server

if __name__ == "__main__":
    base_url = sys.argv[1]
    server = http.server.HTTPServer(('', 8000),
                                    departure_server.request_handler.setup_handler(
                                        RejseplanenQueryStrategy(base_url)))
    server.serve_forever()
