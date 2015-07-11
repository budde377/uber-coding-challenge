# Transitastic
This app solves the problem *departure time* from the uber coding challenge, gives real-time departure time for danish public transportation. The transit-information is aquired through the public available API of Rejseplanen.dk.

## Problem 
[Rejseplanen.dk](http://rejseplanen.dk) is the only provider of danish transit information. Their service is mainly focused on travel-planning, i.e. how to get from A to B, and provides no native service for quick access of departure times for a given station/busstop. Such an service is a usefull for the user who is familiar with the bus-lines, but just want to know when the next bus is departing. It should be accessible from mobile devices and require minimal user interaction.

## Solution
This service solves this problem by implementing a *full-stack* web-service written in Python (v3.4) and Dart (v1.11). The app finds nearby stations/bus-stops, visualized with a list and a map. Departure information can then be accessed by selecting relevant stations. **Why these technologies**

### Frontend
Implemented in HTML, CSS3, and Dart, this service provides a simple design which displays real-time departure information. The design is responsive, which enables access from mobile devices, and features icons from [iconmonstr](http://iconmonstr.com/).

The dart script defines a model (of stations and departures) and `Styler`-classes. This enables a clear distinction between the information avaiable and the logic for displaying this. The styler classes are defined as an `Element` and a `setup` method. The styler should only manipulate the provided element and its children. 

The implementation focuses on minimal client-server interaction, by only fetching departure information lazily and requireing the user to manually fetch new information, and is highly dependent on streams for communicating and propragating updates between instances.

### Backend

REST

## Future work

## Demo
The application can be accessed at [uber.christianbud.de](http://uber.christianbud.de). Locations can be simulated by chaning location hash. E.g.

* Aarhus H: [uber.christianbud.de/#56150156/10204060/0](http://uber.christianbud.de/#56150156/10204060/0)
* Copenhagen H: [uber.christianbud.de/#55673063/12565796/0](http://uber.christianbud.de/#55673063/12565796/0)
* Åes (precision 2km): [uber.christianbud.de/#55918531/9968956/2000](http://uber.christianbud.de/#55918531/9968956/2000)


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
