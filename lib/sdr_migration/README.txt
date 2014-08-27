
Migration notes.

SDR1

The earliest iteration of SDR ingest (aka SDR1) ran on a machine called sdr-ingest, and used a UUID based strategy
for object storage.  Objects were assigned UUIDs then stored in a directory named using that UUID.

SDR2

SDR2 abandoned the UUID approach, initially in favor of using BagIt bags, and later migrated to
use of the moab-versioning approach.

On the production SDR ingest machine there are several NFS filesystems used for object storage, such as:
services-disk
services-disk02
...

The services-disk filesystem uses BagIt storage (SDR2a), and
The services-disk0? filesystems use Moab storage (SDR2b).

SDR2a

		- Alpana Pande designed the original SDR2a ingest robots.
		  - BagIt bags stored in 'deposit-complete' folder using dirs named with dates
		- Richard Anderson took over development
		  - BagIt bags stored in 'druid' folder, in a druid-tree structure

SDR2a Object Collections

        - services-disk contains mostly Google Scanned Book objects
        - other collections on services-disk have already been migrated to SDR2b/Moab structure
            - includes original ETDs and EEMS objects
                - did not delete those originals, however, from SDR2a area (paranoia)
        - only google scanned books still need to be migrated
            - not migrated to SDR2b to avoid duplicate TSM backups
            - but hold off until we have replication to tape in production
            - The Phoenix project was used to ingest google scanned books
               - original development of common accessioning and SDR
               - Cathy Aster managed the Phoenix project

SDR2a -> SDR2b Migration

        - sdr-preservation-core 'sdr_migration' code does the migration from SDR2a/bagIt to SDR2b/Moab

Structure of services-disk/sdr2objects

    - Contains all SDR2a/BagIt data
    - locate objects with ~/bin/druid-path.sh || sdr-preservation-core/bin/storage-path.sh
    - e.g.
        echo "bm331mh9283" | druid-path.sh

    /deposit-complete
        - dated folders contain SDR2a bagIt archives (distinct from /druid)
        - mostly google books that most likely don't need versions
        - not migrated to SDR2b to avoid TSM backups
        - predecessor to /druid
    /druid
        - druid folders contain SDR2a bagIt archives (distinct from /deposit-complete)
        - successor to /deposit-complete
    deposit-complete-bag-verify-output.txt
    deposit-complete-bag-verify.sh
    deposit-complete.toc
    /dor-datastream-cleanup
        - historical; ignore this data
        - Fedora store for datastream objects was cleared of metadata
          already in the SDR2a/bagIt data/content/metadata


SDR2a is a 'bagIt' bag, e.g.

/sdr_services disk/deposit-complete/2010-11-18/druid:bm331mh9283/
|-- bag-info.txt
|-- bagit.txt
|-- data
|   |-- content
|   |   |-- 00000001.html
|   |   |-- 00000001.jp2
|   |   |-- 00000002.html
|   |   |-- 00000002.jp2
...
|   |   |-- 00000086.html
|   |   `-- 00000086.jp2
|   `-- metadata
|       |-- contentMetadata.xml
|       |-- descMetadata.xml
|       |-- googleMETS.xml
|       |-- identityMetadata.xml
|       |-- provenanceMetadata.xml
|       |-- sourceMetadata.xml
|       `-- technicalMetadata.xml
# manifests for data-content
|-- manifest-md5.txt
|-- manifest-sha1.txt
# manifests for bagIt info files
|-- tagmanifest-md5.txt
`-- tagmanifest-sha1.txt


