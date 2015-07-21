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
   
##Loading routing data. PGRouting workshop

Notes from working through http://workshop.pgrouting.org

1. After creating tables with base information
   * gid - global id
   * class_id - Road classification
   * length - of road
   * name - Readable name
   * osm_id
   * the_geom - Postgis geometry

2. Build the topology using pgrouting function via psql or pgadmin.

   tolerance is normally degrees or meters
   ```sql
   --Add columns to hold the source and target vertices 
   ALTER TABLE ways ADD COLUMN "source" integer;
   ALTER TABLE ways ADD COLUMN "target" integer;
   --pgr_createTopology('<table>', float tolerance, '<geometry column', '<gid>')
   pgr_createTopology('ways', 0.00001, 'the_geom', 'gid')
   ```

4. Create indexes so speed up routing.  This should be automatically created by the create topology command
   ```sql
   CREATE INDEX ways_source_idx ON ways("source");
   CREATE INDEX ways_target_idx ON ways("target");
   ```
5. Using Djikstra routing requires reverse_cost column add using:
   ```sql
    ALTER TABLE ways ADD COLUMN reverse_cost double precision;
    UPDATE ways SET reverse_cost = length;   
   ```
   Cost in this case is based on the length of the way, reverse_cost if not required by default
   
   Example query for a route:
   ```
   SELECT seq, id1 AS node, id2 AS edge, cost FROM pgr_dijkstra('
                SELECT gid AS id,
                         source::integer,
                         target::integer,
                         length::double precision AS cost
                        FROM ways',
                30, 60, false, false);
   ```
   
6. Using Shortest path A* alorithm.  This includes geopgraphy about source and target links so it can prefer links which are nearby.
   ```sql
    ALTER TABLE ways ADD COLUMN x1 double precision;
    ALTER TABLE ways ADD COLUMN y1 double precision;
    ALTER TABLE ways ADD COLUMN x2 double precision;
    ALTER TABLE ways ADD COLUMN y2 double precision;  
    --Set x1,y1 as the first point in the linestring
    UPDATE ways SET x1 = ST_x(ST_PointN(the_geom, 1));
    UPDATE ways SET y1 = ST_y(ST_PointN(the_geom, 1));
    --Set x2,y2 as the last point in the linestring
    UPDATE ways SET x2 = ST_x(ST_PointN(the_geom, ST_NumPoints(the_geom)));
    UPDATE ways SET y2 = ST_y(ST_PointN(the_geom, ST_NumPoints(the_geom)));
   ```
   
   Example query:
   ```
   SELECT seq, id1 AS node, id2 AS edge, cost FROM pgr_astar('
                SELECT gid AS id,
                         source::integer,
                         target::integer,
                         length::double precision AS cost,
                         x1, y1, x2, y2
                        FROM ways',
                30, 60, false, false);
   ```
   
7. Calculating multiple shortest paths using kDijisktra

