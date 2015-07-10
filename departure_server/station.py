from datetime import datetime
from xml.etree import ElementTree

from departure_server.query_strategy import QueryStrategy

__author__ = 'budde'


class Position:
    def __init__(self, lat: int, long: int):
        self.lat = lat
        self.long = long

    def __eq__(self, other):
        return isinstance(other, Position) and other.lat == self.lat and other.long == self.long

    def __ne__(self, other):
        return not self == other


class Station:
    def __init__(self, library, station_id: int, name: str, pos: Position):
        """
        :type library: StationLibrary
        """
        self.library = library
        self.query_strategy = library.query_strategy
        self.id = station_id
        self.name = name
        self.pos = pos

    def departures(self) -> list:
        """
        Lists the departures
        :return: A sorted list of departures
        :rtype: list[Departure]
        """
        element = self.query_strategy.departure_time(self.id)
        return \
            list(
                sorted(
                    filter(lambda v: v is not None,
                           map(self.__departure_from_xml, list(element))),
                    key=lambda d: d.date))

    def __departure_from_xml(self, element: ElementTree.Element):
        """
        Creates a Departure instance from a ElementTree.Element
        :param element:
        :return:
        :rtype: Departure
        """
        if 'cancelled' in element.attrib and element.attrib['cancelled'] != 'false':
            return None

        (hour, minute) = element.attrib['rtTime' if 'rtTime' in element.attrib else 'time'].split(':')
        (d, m, y) = element.attrib['rtDate' if 'rtDate' in element.attrib else 'date'].split('.')
        direction = element.attrib['direction'] if 'direction' in element.attrib else ''

        return Departure(self, element.attrib['name'], element.attrib['type'],
                         datetime(int(y) + 2000, int(m), int(d), int(hour), int(minute)), direction)

    def __eq__(self, other):
        return isinstance(other, Station) and self.id == other.id and self.name == other.name and self.pos == other.pos

    def __ne__(self, other):
        return not self == other


class StationLibrary:
    def __init__(self, query_strategy: QueryStrategy):
        self.query_strategy = query_strategy

    def find_nearby(self, pos: Position, radius: int=100) -> list:
        """
        Finds stations near a given position (within a radius).
        Maximum 50 stations are returned
        :param pos: The position
        :param radius: The radius
        :return: A list of Stations
        :rtype: list[Station]
        """
        element = self.query_strategy.find_nearby(pos.lat, pos.long, radius, 50)
        return list(map(self.__station_from_xml, list(element)))

    def station_from_id(self, station_id: int) -> Station:
        """
        Returns a station from a given id.
        A station instance is returned regardless of the existence of the id
        The position and name doesn't need to be correct
        :param station_id: An integer id
        :return: A Station
        :rtype: Station
        """
        return Station(self, station_id, "", Position(0, 0))

    def __station_from_xml(self, element: ElementTree.Element):
        """
        Creates a station given a ElementTree Element.
        It is assumed that the element as attributes: id, name, x, and y
        :param element:
        :return: A station
        :rtype: Station
        """
        return Station(self, int(element.attrib['id']), element.attrib['name'],
                       Position(int(element.attrib['y']), int(element.attrib['x'])))


class Departure:
    """
    A model of a departure
    """
    def __init__(self, station: Station, name: str, departure_type: str, date: datetime, direction: str=""):
        self.station = station
        self.name = name
        self.departure_type = departure_type
        self.date = date
        self.direction = direction

    def __eq__(self, other):
        return isinstance(other, Departure) and other.station == self.station and other.name == self.name \
               and other.departure_type == self.departure_type \
               and other.date == self.date and other.direction == self.direction
