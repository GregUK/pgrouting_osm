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
2. Download osm2po. I had originaly planned to use osm2pgrouting.  See osm2pgrouting README in externals/osm2pgrouting, however due to memory requirements I have now opted for osm2po
   ```
   wget http://osm2po.de/download.php?lnk=osm2po-4.9.1.zip
   ```
3. Unzip osm2po
4. Build/Setup your PostGres database with PostGIS installed.  
   There is a VagrantFile included to do a base build and a setup script used by vagrant which can be used if you want to build in a different way
   see Vagrant-setup/bootstrap_pg.sh
5. Use osm2po to convert the data for loading into postgres.  You will need to accept the licence.  More info on osm2po http://osm2po.de/
   ```
   java -jar osm2po-4.8.8/osm2po-core-4.8.8-signed.jar prefix=gb great-britain-latest.osm.pbf 
   ```
   This will create the SQL to load into postgres and start a local webservice for you test with.
6. Load the data into postgres from the route of the project run:
   ```
   psql -U osmuser -d osm -W -q -f "osm2po-4.8.8/gb/gb_2po_4pgr.sql"
   ```
