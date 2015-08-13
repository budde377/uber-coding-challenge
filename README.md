# Departure Times
This app solves the problem *departure time* from the uber coding challenge, gives real-time departure time for Danish public transportation. The transit-information is acquired through the public available API of Rejseplanen.dk.

## Problem 
[Rejseplanen.dk](http://rejseplanen.dk) is the only provider of Danish transit information. Their service is mainly focused on travel-planning, i.e. how to get from A to B, and provides no native service for quick access of departure times for a given station/bus-stop. Such an service is a useful for the user who is familiar with the bus-lines, but just want to know when the next bus is departing. It should be accessible from mobile devices and require minimal user interaction.

## Solution
This service solves this problem by implementing a *full-stack* web-service written in Python (v3.4) and Dart (v1.11). Besides a general facination of the two languages, Python has been chosen for its compact notation, yielding minimal boilerplate code, and Dart for its liberal type system and nice language features for asynchronous programming. 

The app finds nearby stations/bus-stops, visualized with a list and a map. Departure information can then be accessed by selecting relevant stations. 

### Frontend
Implemented in HTML, CSS3, and Dart, this service provides a simple design which displays real-time departure information. The design is responsive, which enables access from mobile devices, and features icons from [iconmonstr](http://iconmonstr.com/).

The dart script defines a model (of stations and departures) and `Styler`-classes. This enables a clear distinction between the information available and the logic for displaying this. The styler classes are defined as an `Element` and a `setup` method and should only manipulate the provided element and its children. 

The implementation focuses on minimal client-server interaction, by only fetching departure information lazily and requiring the user to manually fetch new information, and is highly dependent on streams for communicating and propagating updates between instances.

### Backend

The server uses the `http.server.HTTPServer` by defining a custom `RequestHandler` (extending the `http.server.SimpleRequestHandler`). This handler supports basic serving of files, e.g. HTML-, CSS-, and Dart-files, and serving of a RESTful API. 

The API currently supports two functions: `/API/1.0/Stations/findNearby?lat={lattitude}&long={longtitude}&radius={radius}`  and `/API/1.0/Stations/departures/{station-id}/` for fetching a list of nearby stations and departures respectively. The API can be easily extended with other functions making it maintainable for future versions.

The API accesses the model of the stations and departures. These are constructed from data accessible via. the API of [rejseplanen.dk](http://rejseplanen.dk). Currently no instances of the model are cached, forcing every request to make a call to the external resources. Caching of stations has been considered and would probably prove performance enhancing when multiple users are accessing the same information at the same time. It has however not been implemented because [rejseplanen.dk](http://rejseplanen.dk) promises no persistence of IDs over time, i.e. station IDs might change on a weekly basis. 

## Future work

As mentioned in the previous section, server-side caching should be implemented. Special care should be taken regarding the problem of the changing IDs. A solution could be only to create new `Station` instances when new  information of a corresponding ID is observed. This would enable caching of departure times.

Currently the app supports no obvious way to dynamically changing the radius or center of the search area for nearby stations, this might impose a problem when stations are sparse.

Some stations, such as *København H* or *Park allé* in Aarhus, are serving many departures every minute. The current implementation only displays the next 20 departures, which in practice might only give an overview of departures within the next 5 minutes. In these cases it should be possible to load more departures.

## Demo
The application can be accessed at [uber.christianbud.de](http://uber.christianbud.de). Locations can be simulated by changing location hash. E.g.

* Aarhus H: [uber.christianbud.de/#56150156/10204060/0](http://uber.christianbud.de/#56150156/10204060/0)
* København H: [uber.christianbud.de/#55673063/12565796/0](http://uber.christianbud.de/#55673063/12565796/0)
* Åes (precision 2 km): [uber.christianbud.de/#55918531/9968956/2000](http://uber.christianbud.de/#55918531/9968956/2000)

## About me
My name is Christian Budde Christensen and I have a master degree in computer science from Aarhus University. I am quite experienced with Dart though my open source CMS; [Part](https://github.com/budde377/Part), and have some experience with Python through various projects e.g. in my [masters thesis](https://github.com/silwing/tapas). My professional public profile can be found on [LinkedIn](https://dk.linkedin.com/in/christianbudde) and my resume acquired upon request.

<!---
Create a service that gives real-time departure time for public transportation (use freely available public API). The app should geolocalize the user.

Regardless of whether it's your own code or our coding challenge, write your README as if it was for a production service. Include the following items:

* Description of the problem and solution.
* Whether the solution focuses on back-end, front-end or if it's full stack.
* Reasoning behind your technical choices, including architectural. Trade-offs you might have made, anything you left out, or what you might do differently if you were to spend additional time on the project.
* Link to other code you're particularly proud of.
* Link to your resume or public profile.
* Link to to the hosted application where applicable.
-->
