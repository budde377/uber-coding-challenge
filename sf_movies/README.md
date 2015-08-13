SF Locations
============

TODO:
----

* Parse CSV file of movies.
    - Translate locations using Google Maps
* Implement REST API
    - String query
    - Location range query
* Implement front-end
    - Map and a search field?


Initial map: All locations (~1000)? Then the filtering can be performed client-side. => No need for REST API, data can be passed through HTML (using data attributes)

HTML
----

- div, container
    * div, movie (@-title)
        - div, location (@-location)
