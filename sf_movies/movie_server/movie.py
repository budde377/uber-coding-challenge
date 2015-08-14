__author__ = 'budde'


class Movie:
    def __init__(self, title, locations=None):
        self.coordinates = None
        self.title = title
        self.locations = [] if not locations else locations
