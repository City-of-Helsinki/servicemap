[![Stories in Ready](https://badge.waffle.io/City-of-Helsinki/servicemap.png?label=ready&title=Ready)](https://waffle.io/City-of-Helsinki/servicemap)
# Service Map front end

Service Map is a web application for making the services in a location
visible and discoverable through a friendly map interface. It is geared
towards showing services provided to citizens by cities.

Some of the things Service Map can do:
* show a pretty map :)
  * the map can be customized to cater for differences in vision
  * the map can show different styles of maps
  * the map can be overlaid with statiscal layers (population density)
* search for, and display on map:
  * service locations through a drill-down list and search
  * addresses
  * routes to a found location (accomodating for differences in moving)
* for location
  * show route (using external Digitransit API)
  * show services allocated for people living at that address
  * show the communal districts for that location
* for service
  * description
  * route
  * how reachable the service is for different ways of moving
  * receive and forward feedback for services (through Open311 API)

and much more!

Look at the Helsinki site the see Service Map in action.

## Setup

### Prequisites

* Unix-like OS (Linux is the main platform, Mac OS is tested often)
* Node v8 LTS

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