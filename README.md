# pgrouting_osm

## Requirements

TBD

## Documentation

See in the documentation of the pgrouting website for more informations: http://pgrouting.org

## Installation

1. Download PBF OSM data from http://download.geofabrik.de/europe.html for your region of interest.
   ```
   wget http://download.geofabrik.de/europe/great-britain-latest.osm.pbf
   ```
2. Build the osm2pgrouting binaries for importing the OSM data to PostGres.  See osm2pgrouting README in externals/osm2pgrouting
3. Build/Setup your PostGres database with PostGIS installed.  
   There is a VagrantFile included to do a base build and a setup script used by vagrant which can be used if you want to build in a different way
   see Vagrant-setup/bootstrap_pg.sh
4. Install the PBF data into postgres