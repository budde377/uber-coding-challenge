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
        element = self.query_strategy.departure_time(self.id)
        return list(filter(lambda v: v is not None, map(self.__departure_from_xml, list(element))))

    def __departure_from_xml(self, element: ElementTree.Element):
        if 'cancelled' in element.attrib and element.attrib['cancelled'] != 'false':
            return None

        (hour, minute) = element.attrib['time'].split(':')
        (d, m, y) = element.attrib['date'].split('.')
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
        element = self.query_strategy.find_nearby(pos.lat, pos.long, radius, 50)
        stations = []
        for child in element:
            stations.append(self.__station_from_xml(child))
        return stations

    def station_from_name(self, name: str) -> list:
        element = self.query_strategy.search_stop(name)
        return list(map(self.__station_from_xml,
                        filter(lambda e: e.tag == "StopLocation" and e.attrib['name'] == name, list(element))))

    def station_from_id(self, station_id: int) -> Station:
        return Station(self, station_id, "", Position(0, 0))

    def __station_from_xml(self, element):
        return Station(self, int(element.attrib['id']), element.attrib['name'],
                       Position(int(element.attrib['x']), int(element.attrib['y'])))


class Departure:
    def __init__(self, station: Station, name: str, departure_type: str, date: datetime, direction: str=""):
        self.station = station
        self.name = name
        self.departure_type = departure_type
        self.date = date
        self.direction = direction

    def __eq__(self, other):
        return isinstance(other, Departure) and other.station == self.station and other.name == self.name \
               and other.departure_type == self.departure_type \
               and other.date == self.date and other.direction == self.direction \
