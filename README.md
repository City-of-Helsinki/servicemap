[![Stories in Ready](https://badge.waffle.io/City-of-Helsinki/servicemap.png?label=ready&title=Ready)](https://waffle.io/City-of-Helsinki/servicemap)
# Service Map: make your services discoverable

Service Map is a web application for making the services in a location
visible and discoverable through a friendly map interface. It is geared
towards showing services provided to citizens by cities.

Some of the things Service Map can do:
* show services on map, based on all sorts of filters
* browse services through a tree, or search for them
* show detailed information for service found
* show services available for a certain location

and much more! (really!)

Look at the [Helsinki site](https://servicemap.hel.fi) to see Service Map in action.

## Data sources needed

To perform its magic, Service Map needs data. Quite a lot of it. What
follows are the types of sources that it can use. The first two are
mandatory if you want to make any use of Service Map at all.

### Service Map API: services and locations through a REST API (mandatory)

Service Map uses its own REST API to access information about services and
their locations. Its counterpart
(smbackend)(https://https://github.com/City-of-Helsinki/smbackend)
implements the server side of this API. You will most likely want to run
your own instance, if you wish to use Service Map.

The specifics of the API are documented with the smbackend. Here we just
note that the backend does not provide any editing capabitilities. Instead
you will need to create your data translator that feeds the backend with the
necessary data.

### WMTS or WMS API: background map tiles (mandatory)

For Service Map to be useful, it needs the actual map images. Service Map
uses [Leaflet](https://leafletjs.com/) internally to display the map. This
means that the map needs to be available in using WMTS or TMS api, or
something similar to them. This format is exceedingly popular, to the extent
that you are unlikely to find a map source that is not compatible.

If you wish to create your own map tiles with your own style, you will need
to set up a tile rendering pipeline with your own styles (and create the
styles, of course). That is way out of scope for this README.

### Open311 API: allow users to leave feedback for services (optional)

Service Map can show a button for leaving feedback on services and
locations. For that to work, you will need to point it to a
[Open311](http://www.open311.org/) API endpoint, which in turn
is connected to some system where the feedback is processed.

### Linkedevents API: show events happenin' at locations (optional)

Service Map can show events happening at locations on map. For this
to work, you will need a Linkedevents API endpoint. It so happens,
that [Linkedevents](https://github.com/City-of-Helsinki/linkedevents)
implements this API. Setting up and using Linkedevents is also way
out of scope

### Respa API: show reservable resources at locations (optional)

If you have a Respa API implementation available, Service Map can
use it to check if a location has reservable resources (like working spaces)
available to the public. It so happens that
[Respa](https://github.com/City-of-Helsinki/respa) implements
Respa API, just in case you are interested.

## Setup

### Prequisites

* Unix-like OS (Linux is the main platform, Mac OS is tested often)
* Node v8 LTS
* Reasonably modern web browser

### Setting up for development or generally poking around

No configuration is necessary for getting started. Default configuration
points to the City of Helsinki backend servers, which are publicly
available.

Clone the repository:
`git clone https://github.com/City-of-Helsinki/servicemap.git`

Install the dependencies:
```shell
cd servicemap
npm install
```

Start the development server:
`npm start`

Service Map is now accessible via the browser at:

http://127.0.0.1:9001/

The development environment supports hot reloading, so no need to restart
the servers to see what any changes do.

### Configuration

All available configuration variables are listed in config/default.yml,
along with comments explaining their use. default.yml is also the actual
sources for default values.

To change any settings, do not directly edit `config/default.yml`. Instead
either:
* create `config/local.yml` and define wanted settings therein
* set environment variables as defined in `custom-environment-variables.yml`

First option is generally what you want in development. In production your
environmental scaffolding is likely to support injecting configuration
through environment variables.

### Running in production

Production setup is not much diffent from development. First build and
install all the assets:

```shell
npm run build
```

The assets will end up in `static`-folder. It is possible to move the
contents to another server or CDN. See `config/default.yml` for the
configuration variable to change.

Additionally you will need to run the small server, which generates a
starting page for the app with appropriate configuration injected.

```shell
npm run production
```

This will output the current configuration and start the server.