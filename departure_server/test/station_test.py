from datetime import datetime
from unittest import TestCase

from departure_server.query_strategy import StubQueryStrategy
from departure_server.station import StationLibrary, Position, Station, Departure

__author__ = 'budde'


class TestStationLibrary(TestCase):
    def setUp(self):
        self.query_strategy = StubQueryStrategy()
        self.lib = StationLibrary(self.query_strategy)

    def test_find_nearby(self):
        stations = self.lib.find_nearby(Position(0, 0))
        other = [Station(self.lib, 8600626, "København H", Position(12565796, 55673063)),
                 Station(self.lib, 10844, "Hovedbanegården, Tivoli", Position(12566191, 55672838)),
                 Station(self.lib, 100240000, "København, Bernstorffsgade (fjernbus)",
                         Position(12565112, 55673899))]

        self.assertEqual(other, stations)

    def test_strategy_find_called_with_right_parameters(self):
        self.lib.find_nearby(Position(1, 2))
        self.assertEqual([('find_nearby', [1, 2, 100, 100])], self.query_strategy.called)

    def test_first_station_in_search_result(self):
        station = self.lib.station_from_name('Some name')
        self.assertEqual(Station(self.lib, 519002300, 'Velkær', Position(9546732, 54997056)), station)

    def test_strategy_station_called_with_right_parameters(self):
        self.lib.station_from_name("Bob")
        self.assertEqual([('search_stop', ["Bob"])], self.query_strategy.called)


class TestStation(TestCase):
    def setUp(self):
        self.query_strategy = StubQueryStrategy()
        self.lib = StationLibrary(self.query_strategy)
        self.station = self.lib.find_nearby(Position(0, 0))[0]
        self.query_strategy.called = []

    def test_station_departure_times(self):
        departures = self.station.departures()
        other = [
            Departure(self.station, "Re 2221", "REG", datetime(2015, 7, 7, 10, 11), "Nykøbing F St.",
                      Station(self.lib, 519002300, 'Velkær', Position(9546732, 54997056))),
            Departure(self.station, "ØR 2037", "TOG", datetime(2015, 7, 7, 10, 12),
                      final_stop=Station(self.lib, 519002300, 'Velkær', Position(9546732, 54997056))),
            Departure(self.station, "ØR 1036", "TOG", datetime(2015, 7, 7, 10, 12),
                      direction='Hässleholm C og Kalmar C')
        ]
        self.assertEqual(other, departures)

    def test_strategy_called_right(self):
        self.station.departures()
        self.assertEqual([('departure_time', [8600626, True, True, True]),
                          ('search_stop', ['Nykøbing F St.']),
                          ('search_stop', ['Helsingør St.'])], self.query_strategy.called)
