import urllib.request
from xml.etree import ElementTree

__author__ = 'budde'

_nearby = """<?xml version="1.0" encoding="UTF-8"?>
<LocationList xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://xmlopen.rejseplanen.dk/xml/rest/hafasRestStopsNearby.xsd">
<StopLocation name="København H" x="12565796" y="55673063" id="8600626" distance="1" />
<StopLocation name="Hovedbanegården, Tivoli" x="12566191" y="55672838" id="10844" distance="34" />
<StopLocation name="København, Bernstorffsgade (fjernbus)" x="12565112" y="55673899" id="100240000" distance="103" /></LocationList>
"""
_search = """<?xml version="1.0" encoding="UTF-8"?>
<LocationList xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://xmlopen.rejseplanen.dk/xml/rest/hafasRestLocation.xsd">
<CoordLocation name="Gyvelhøj 3370 Melby, Halsnæs Kommune" x="11946043" y="55992953" type="ADR" />
<StopLocation name="Velkær" x="9546732" y="54997056" id="519002300" />
<StopLocation name="Velling" x="9582617" y="55624341" id="603330500" />
<CoordLocation name="Skelbyvej Bavelse Mlgd, 4171 Glumsø, Næstved Kommu" x="11665022" y="55328686" type="ADR" />
</LocationList>
"""

_departure = """<?xml version="1.0" encoding="UTF-8"?>
<DepartureBoard xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:noNamespaceSchemaLocation="http://xmlopen.rejseplanen.dk/xml/rest/hafasRestDepartureBoard.xsd">
<Departure name="Re 2221" type="REG" stop="København H" time="10:11" date="07.07.15" messages="0" track="7" rtTrack="7" finalStop="Nykøbing F St." direction="Nykøbing F St.">
<JourneyDetailRef ref="http://xmlopen.rejseplanen.dk/bin/rest.exe/journeyDetail?ref=578919%2F203001%2F147318%2F119314%2F86%3Fdate%3D07.07.15" />
</Departure>
<Departure name="ØR 2037" type="TOG" stop="København H" time="10:12" date="07.07.15" messages="0" track="1" rtTrack="1" finalStop="Helsingør St." >
<JourneyDetailRef ref="http://xmlopen.rejseplanen.dk/bin/rest.exe/journeyDetail?ref=200007%2F99281%2F36180%2F48582%2F86%3Fdate%3D07.07.15" />
</Departure>
<Departure name="ØR 1036" type="TOG" stop="København H" time="10:12" date="07.07.15" messages="0" track="5" rtTrack="5" direction="Hässleholm C og Kalmar C">
<JourneyDetailRef ref="http://xmlopen.rejseplanen.dk/bin/rest.exe/journeyDetail?ref=284772%2F128050%2F55102%2F67373%2F86%3Fdate%3D07.07.15" />
</Departure>
<Departure name="ØR 1036" type="TOG" stop="København H" time="10:12" date="07.07.15" messages="0" track="5" rtTrack="5" cancelled="true" direction="Hässleholm C og Kalmar C">
<JourneyDetailRef ref="http://xmlopen.rejseplanen.dk/bin/rest.exe/journeyDetail?ref=284772%2F128050%2F55102%2F67373%2F86%3Fdate%3D07.07.15" />
</Departure>
</DepartureBoard>
"""


class QueryStrategy:
    def find_nearby(self, x: int, y: int, max_radius: int, max_number: int) -> ElementTree.Element:
        raise NotImplemented

    def search_stop(self, name: str) -> ElementTree.Element:
        raise NotImplemented

    def departure_time(self, stop_id: int, use_bus=True, use_tog=True, use_metro=True) -> ElementTree.Element:
        raise NotImplemented


class StubQueryStrategy(QueryStrategy):
    def __init__(self, nearby: ElementTree.Element=None, search: ElementTree.Element=None,
                 departure: ElementTree.Element=None):
        self.nearby = nearby if nearby is not None else ElementTree.fromstring(_nearby)
        self.search = search if search is not None else ElementTree.fromstring(_search)
        self.departure = departure if departure is not None else ElementTree.fromstring(_departure)
        self.called = []

    def find_nearby(self, x: int, y: int, max_radius: int, max_number: int) -> ElementTree.Element:
        self.called.append(('find_nearby', [x, y, max_radius, max_number]))
        return self.nearby

    def search_stop(self, name: str) -> ElementTree.Element:
        self.called.append(('search_stop', [name]))
        return self.search

    def departure_time(self, stop_id: int, use_bus=True, use_tog=True, use_metro=True) -> ElementTree.Element:
        self.called.append(('departure_time', [stop_id, use_bus, use_tog, use_metro]))
        return self.departure


class RejseplanenQueryStrategy(QueryStrategy):
    def __init__(self, base_url: str):
        self.base_url = base_url

    def find_nearby(self, x: int, y: int, max_radius: int, max_number: int) -> ElementTree.Element:
        return self._read_url(
            "stopsNearby?coordX=%d&coordY=%d&maxRadius=%d&maxNumber=%d" % (x, y, max_radius, max_number))

    def search_stop(self, name: str) -> ElementTree.Element:
        return self._read_url("location?input=%s" % name)

    def departure_time(self, stop_id: int, use_bus=True, use_tog=True, use_metro=True) -> ElementTree.Element:
        return self._read_url(
            "departureBoard?useBus=%d&useTog=%d&useMetro=%d&id=%d" % (use_bus, use_tog, use_metro, stop_id))

    def _read_url(self, address: str) -> ElementTree.Element:
        data = urllib.request.urlopen("%s/%s" % (self.base_url, address)).read()
        return ElementTree.fromstring(data)
