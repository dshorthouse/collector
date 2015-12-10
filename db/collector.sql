SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;


CREATE TABLE IF NOT EXISTS `agents` (
`id` int(11) NOT NULL,
  `canonical_id` int(11) DEFAULT NULL,
  `family` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `given` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `gender` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `orcid_identifier` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `position` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `affiliation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `processed_orcid` tinyint(1) DEFAULT NULL,
  `processed_profile` tinyint(1) DEFAULT NULL,
  `processed_barcodes` tinyint(1) DEFAULT NULL,
  `processed_datasets` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=60266 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `agent_barcodes` (
`id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `barcode_id` int(11) NOT NULL,
  `original_agent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=212801 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `agent_datasets` (
`id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `dataset_id` int(11) NOT NULL,
  `original_agent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=144933 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `agent_descriptions` (
`id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `description_id` int(11) NOT NULL,
  `original_agent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=1817 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `agent_works` (
`id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `work_id` int(11) NOT NULL,
  `original_agent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3242 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `baby_names` (
`id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `rating_count` int(11) DEFAULT NULL,
  `rating_total` decimal(10,0) DEFAULT NULL,
  `rating_avg` decimal(10,2) DEFAULT NULL,
  `is_popular` tinyint(1) DEFAULT '0'
) ENGINE=MyISAM AUTO_INCREMENT=129200 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `barcodes` (
`id` int(11) NOT NULL,
  `processid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `bin_uri` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `catalognum` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=207873 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `datasets` (
`id` int(11) NOT NULL,
  `doi` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `title` text COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=41034 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `descriptions` (
`id` int(11) NOT NULL,
  `scientificName` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `year` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2386 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `occurrences` (
  `id` int(11) NOT NULL,
  `acceptedNameUsage` text COLLATE utf8_unicode_ci,
  `associatedMedia` text COLLATE utf8_unicode_ci,
  `associatedOccurrences` text COLLATE utf8_unicode_ci,
  `associatedReferences` text COLLATE utf8_unicode_ci,
  `associatedSequences` text COLLATE utf8_unicode_ci,
  `associatedTaxa` text COLLATE utf8_unicode_ci,
  `basisOfRecord` text COLLATE utf8_unicode_ci,
  `behavior` text COLLATE utf8_unicode_ci,
  `bibliographicCitation` text COLLATE utf8_unicode_ci,
  `catalogNumber` text COLLATE utf8_unicode_ci,
  `_class` text COLLATE utf8_unicode_ci,
  `collectionCode` text COLLATE utf8_unicode_ci,
  `collectionID` text COLLATE utf8_unicode_ci,
  `continent` text COLLATE utf8_unicode_ci,
  `coordinateUncertaintyInMeters` text COLLATE utf8_unicode_ci,
  `country` text COLLATE utf8_unicode_ci,
  `countryCode` text COLLATE utf8_unicode_ci,
  `county` text COLLATE utf8_unicode_ci,
  `datasetID` text COLLATE utf8_unicode_ci,
  `datasetName` text COLLATE utf8_unicode_ci,
  `dateIdentified` text COLLATE utf8_unicode_ci,
  `decimalLatitude` text COLLATE utf8_unicode_ci,
  `decimalLongitude` text COLLATE utf8_unicode_ci,
  `disposition` text COLLATE utf8_unicode_ci,
  `dynamicProperties` text COLLATE utf8_unicode_ci,
  `establishmentMeans` text COLLATE utf8_unicode_ci,
  `eventDate` text COLLATE utf8_unicode_ci,
  `eventRemarks` text COLLATE utf8_unicode_ci,
  `eventTime` text COLLATE utf8_unicode_ci,
  `family` text COLLATE utf8_unicode_ci,
  `fieldNotes` text COLLATE utf8_unicode_ci,
  `footprintWKT` text COLLATE utf8_unicode_ci,
  `genus` text COLLATE utf8_unicode_ci,
  `geodeticDatum` text COLLATE utf8_unicode_ci,
  `georeferencedBy` text COLLATE utf8_unicode_ci,
  `georeferencedDate` text COLLATE utf8_unicode_ci,
  `georeferenceProtocol` text COLLATE utf8_unicode_ci,
  `georeferenceRemarks` text COLLATE utf8_unicode_ci,
  `georeferenceSources` text COLLATE utf8_unicode_ci,
  `georeferenceVerificationStatus` text COLLATE utf8_unicode_ci,
  `habitat` text COLLATE utf8_unicode_ci,
  `higherClassification` text COLLATE utf8_unicode_ci,
  `higherGeography` text COLLATE utf8_unicode_ci,
  `identificationQualifier` text COLLATE utf8_unicode_ci,
  `identificationReferences` text COLLATE utf8_unicode_ci,
  `identificationRemarks` text COLLATE utf8_unicode_ci,
  `identifiedBy` text COLLATE utf8_unicode_ci,
  `individualCount` text COLLATE utf8_unicode_ci,
  `infraspecificEpithet` text COLLATE utf8_unicode_ci,
  `institutionCode` text COLLATE utf8_unicode_ci,
  `islandGroup` text COLLATE utf8_unicode_ci,
  `kingdom` text COLLATE utf8_unicode_ci,
  `language` text COLLATE utf8_unicode_ci,
  `lifeStage` text COLLATE utf8_unicode_ci,
  `locality` text COLLATE utf8_unicode_ci,
  `locationAccordingTo` text COLLATE utf8_unicode_ci,
  `locationRemarks` text COLLATE utf8_unicode_ci,
  `maximumElevationInMeters` text COLLATE utf8_unicode_ci,
  `minimumElevationInMeters` text COLLATE utf8_unicode_ci,
  `modified` text COLLATE utf8_unicode_ci,
  `municipality` text COLLATE utf8_unicode_ci,
  `nomenclaturalCode` text COLLATE utf8_unicode_ci,
  `occurrenceRemarks` text COLLATE utf8_unicode_ci,
  `_order` text COLLATE utf8_unicode_ci,
  `otherCatalogNumbers` text COLLATE utf8_unicode_ci,
  `ownerInstitutionCode` text COLLATE utf8_unicode_ci,
  `phylum` text COLLATE utf8_unicode_ci,
  `preparations` text COLLATE utf8_unicode_ci,
  `previousIdentifications` text COLLATE utf8_unicode_ci,
  `recordedBy` text COLLATE utf8_unicode_ci,
  `recordNumber` text COLLATE utf8_unicode_ci,
  `_references` text COLLATE utf8_unicode_ci,
  `reproductiveCondition` text COLLATE utf8_unicode_ci,
  `rights` text COLLATE utf8_unicode_ci,
  `rightsHolder` text COLLATE utf8_unicode_ci,
  `samplingProtocol` text COLLATE utf8_unicode_ci,
  `scientificName` text COLLATE utf8_unicode_ci,
  `scientificNameAuthorship` text COLLATE utf8_unicode_ci,
  `sex` text COLLATE utf8_unicode_ci,
  `specificEpithet` text COLLATE utf8_unicode_ci,
  `stateProvince` text COLLATE utf8_unicode_ci,
  `subgenus` text COLLATE utf8_unicode_ci,
  `taxonRank` text COLLATE utf8_unicode_ci,
  `taxonRemarks` text COLLATE utf8_unicode_ci,
  `_type` text COLLATE utf8_unicode_ci,
  `typeStatus` text COLLATE utf8_unicode_ci,
  `verbatimCoordinates` text COLLATE utf8_unicode_ci,
  `verbatimCoordinateSystem` text COLLATE utf8_unicode_ci,
  `verbatimDepth` text COLLATE utf8_unicode_ci,
  `verbatimElevation` text COLLATE utf8_unicode_ci,
  `verbatimEventDate` text COLLATE utf8_unicode_ci,
  `verbatimLatitude` text COLLATE utf8_unicode_ci,
  `verbatimLocality` text COLLATE utf8_unicode_ci,
  `verbatimLongitude` text COLLATE utf8_unicode_ci,
  `verbatimSRS` text COLLATE utf8_unicode_ci,
  `vernacularName` text COLLATE utf8_unicode_ci,
  `waterBody` text COLLATE utf8_unicode_ci,
  `year` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `occurrence_determiners` (
`id` int(11) NOT NULL,
  `occurrence_id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `original_agent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=1421535 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `occurrence_recorders` (
`id` int(11) NOT NULL,
  `occurrence_id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `original_agent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3275748 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `taxa` (
`id` int(11) NOT NULL,
  `kingdom` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phylum` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `_class` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `_order` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `family` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `common` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `image` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB AUTO_INCREMENT=1966 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `taxon_determiners` (
`id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `taxon_id` int(11) NOT NULL,
  `original_agent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=1189006 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `taxon_occurrences` (
`id` int(11) NOT NULL,
  `occurrence_id` int(11) NOT NULL,
  `taxon_id` int(11) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=1135601 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE IF NOT EXISTS `works` (
`id` int(11) NOT NULL,
  `doi` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `citation` text COLLATE utf8_unicode_ci,
  `processed` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2982 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


ALTER TABLE `agents`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `full_name` (`family`,`given`);

ALTER TABLE `agent_barcodes`
 ADD PRIMARY KEY (`id`), ADD KEY `idx_agent` (`agent_id`), ADD KEY `idx_agent_original` (`original_agent_id`), ADD KEY `idx_barcode` (`barcode_id`);

ALTER TABLE `agent_datasets`
 ADD PRIMARY KEY (`id`), ADD KEY `idx_datasets` (`dataset_id`), ADD KEY `idx_agents` (`agent_id`);

ALTER TABLE `agent_descriptions`
 ADD PRIMARY KEY (`id`), ADD KEY `idx_agent` (`agent_id`), ADD KEY `idx_description` (`description_id`);

ALTER TABLE `agent_works`
 ADD PRIMARY KEY (`id`), ADD KEY `agent_id` (`agent_id`), ADD KEY `work_id` (`work_id`);

ALTER TABLE `baby_names`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `index_names_on_name_and_gender` (`name`,`gender`), ADD KEY `gender` (`gender`), ADD KEY `rating_avg` (`rating_avg`), ADD KEY `index_names_on_is_popular` (`is_popular`);

ALTER TABLE `barcodes`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `processid_idx` (`processid`);

ALTER TABLE `datasets`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `doi` (`doi`);

ALTER TABLE `descriptions`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `idx_scientific_name` (`scientificName`);

ALTER TABLE `occurrences`
 ADD PRIMARY KEY (`id`), ADD FULLTEXT KEY `idx_recordedby` (`recordedBy`);

ALTER TABLE `occurrence_determiners`
 ADD PRIMARY KEY (`id`), ADD KEY `agent_idx` (`agent_id`), ADD KEY `occurrence_idx` (`occurrence_id`);

ALTER TABLE `occurrence_recorders`
 ADD PRIMARY KEY (`id`), ADD KEY `agent_idx` (`agent_id`), ADD KEY `occurrence_idx` (`occurrence_id`);

ALTER TABLE `schema_migrations`
 ADD UNIQUE KEY `unique_schema_migrations` (`version`);

ALTER TABLE `taxa`
 ADD PRIMARY KEY (`id`), ADD UNIQUE KEY `family_idx` (`family`), ADD KEY `kingdom_idx` (`kingdom`), ADD KEY `phylum_idx` (`phylum`);

ALTER TABLE `taxon_determiners`
 ADD PRIMARY KEY (`id`), ADD KEY `agent_idx` (`agent_id`), ADD KEY `taxon_idx` (`taxon_id`);

ALTER TABLE `taxon_occurrences`
 ADD PRIMARY KEY (`id`), ADD KEY `occurrence_idx` (`occurrence_id`), ADD KEY `taxon_idx` (`taxon_id`);

ALTER TABLE `works`
 ADD PRIMARY KEY (`id`), ADD KEY `doi` (`doi`);


ALTER TABLE `agents`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=60266;
ALTER TABLE `agent_barcodes`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=212801;
ALTER TABLE `agent_datasets`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=144933;
ALTER TABLE `agent_descriptions`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1817;
ALTER TABLE `agent_works`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3242;
ALTER TABLE `baby_names`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=129200;
ALTER TABLE `barcodes`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=207873;
ALTER TABLE `datasets`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=41034;
ALTER TABLE `descriptions`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2386;
ALTER TABLE `occurrence_determiners`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1421535;
ALTER TABLE `occurrence_recorders`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3275748;
ALTER TABLE `taxa`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1966;
ALTER TABLE `taxon_determiners`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1189006;
ALTER TABLE `taxon_occurrences`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=1135601;
ALTER TABLE `works`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2982;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
