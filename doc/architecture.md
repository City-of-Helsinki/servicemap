# Service Map - System Architecture

The Service Map is an interactive web application which helps users
discover and search for local, physical services available in their
city.

## Components

The Service map consists of

-  a
   [client application](https://www.github.com/City-of-Helsinki/servicemap)
   which runs the **user interface** in the web browser, and
-  a
   [server component](https://www.github.com/City-of-Helsinki/smbackend)
   which provides the **data** through a RESTful API.

Additional server components are required for specific functionality:

-  a
   [Linked Events](https://www.github.com/City-of-Helsinki/linkedevents)
   compatible REST API for **event data**, and
-  an [Open Trip Planner](http://www.opentripplanner.org/) instance
   for **transportation route planning**.

## High level component architecture

The server components contain no user interface logic. They are
read-only RESTful APIs that are only concerned with providing JSON
data when queried for it using filters and identifiers. *All* the data
required by the user interface is provided by the APIs.

The user interface is an HTML5 JavaScript application running in the
browser. It queries the required data on-demand from the backend
components and renders the views dynamically.

### The back end

This documentation focuses on the main
[server component](https://www.github.com/City-of-Helsinki/smbackend)
which provides data about

- categorized services ("day care")
- service points which provide these services in actual physical
  locations ("Day care Albert")
- accessibility of the service points
- addresses (geocoding / reverse geocoding)
- geographical divisions

The server component acts as a simple querying and filtering cache
layer and is not currently the authoritative master source for the
data. The data is imported from the master database periodically. This
allows implementing new filtering functionality in the back end
quickly and iteratively and ensuring high performance for queries
required by the front end.

The server component is a Django application which runs
on the following stack.

- python 3
- Django
- Django REST Framework
- PostgreSQL
- PostGIS for geographical queries
- ElasticSearch for full text queries

#### Internal architecture

The internal architecture of the server component follows the
conventions of Django applications, and the back-end app can thus be
considered an MVC application.

### The front end

The
[front-end component](https://www.github.com/City-of-Helsinki/smbackend)
is an HTML5 JavaScript application. In theory it requires only a web
browser which loads the application HTML, JavaScript and static assets
and runs the Javascript. However, to provide appropriate metadata for
social media applications and search engine web crawlers, there is a
server side Node.js Express Server which injects minimal amounts of
data about the service points into the application HTML.

The front end is built on the following stack.

- CoffeeScript
- Backbone and Marionette
- Leaflet.js
- Node.js and Express Server
- The *development environment* is based on Grunt and Node.js.

#### Internal architecture

The front end component follows a variation of the MVC architecture
pattern. The view components rarely contain any substantial state, and
user interactions are forwarded via a command mechanism to a central
orchestrating controller component which coordinates changes to the
model instances.

## Deployment considerations

In the [Helsinki deployment](http://servicemap.hel.fi), the Service
map has been deployed to a self-sufficient virtual server containing
both the front-end and back-end components.

A Varnish cache is recommended on front of the server component if
it's not deployed as part of a API management solution with caching.
