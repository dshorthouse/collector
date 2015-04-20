CREATE TABLE `collector`.`agents` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `family` varchar(255) DEFAULT NULL, 
  `given` varchar(255) DEFAULT NULL, 
  `suffix` varchar(108) DEFAULT NULL, 
PRIMARY KEY `PRIMARY` (`id`),
UNIQUE KEY `full_name` (`family`,`given`)
) ENGINE=InnoDB;

# Reading .frm file for collector_dev/occurrence_collectors.frm:
# The .frm file is a TABLE.
# CREATE TABLE Statement:

CREATE TABLE `collector`.`occurrence_collectors` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `occurrence_id` int(11) NOT NULL, 
  `agent_id` int(11) NOT NULL, 
PRIMARY KEY `PRIMARY` (`id`)
) ENGINE=InnoDB;

# Reading .frm file for collector_dev/occurrence_determinors.frm:
# The .frm file is a TABLE.
# CREATE TABLE Statement:

CREATE TABLE `collector`.`occurrence_determinors` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `occurrence_id` int(11) NOT NULL, 
  `agent_id` int(11) NOT NULL, 
PRIMARY KEY `PRIMARY` (`id`)
) ENGINE=InnoDB;

# Reading .frm file for collector_dev/occurrences.frm:
# The .frm file is a TABLE.
# CREATE TABLE Statement:

CREATE TABLE `collector`.`occurrences` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `acceptedNameUsage` text DEFAULT NULL, 
  `associatedMedia` text DEFAULT NULL, 
  `associatedOccurrences` text DEFAULT NULL, 
  `associatedReferences` text DEFAULT NULL, 
  `associatedSequences` text DEFAULT NULL, 
  `associatedTaxa` text DEFAULT NULL, 
  `basisOfRecord` text DEFAULT NULL, 
  `behavior` text DEFAULT NULL, 
  `bibliographicCitation` text DEFAULT NULL, 
  `catalogNumber` text DEFAULT NULL, 
  `_class` text DEFAULT NULL, 
  `collectionCode` text DEFAULT NULL, 
  `collectionID` text DEFAULT NULL, 
  `continent` text DEFAULT NULL, 
  `coordinateUncertaintyInMeters` text DEFAULT NULL, 
  `country` text DEFAULT NULL, 
  `countryCode` text DEFAULT NULL, 
  `county` text DEFAULT NULL, 
  `datasetID` text DEFAULT NULL, 
  `datasetName` text DEFAULT NULL, 
  `dateIdentified` text DEFAULT NULL, 
  `decimalLatitude` text DEFAULT NULL, 
  `decimalLongitude` text DEFAULT NULL, 
  `disposition` text DEFAULT NULL, 
  `dynamicProperties` text DEFAULT NULL, 
  `establishmentMeans` text DEFAULT NULL, 
  `eventDate` text DEFAULT NULL, 
  `eventRemarks` text DEFAULT NULL, 
  `eventTime` text DEFAULT NULL, 
  `family` text DEFAULT NULL, 
  `fieldNotes` text DEFAULT NULL, 
  `footprintWKT` text DEFAULT NULL, 
  `genus` text DEFAULT NULL, 
  `geodeticDatum` text DEFAULT NULL, 
  `georeferencedBy` text DEFAULT NULL, 
  `georeferencedDate` text DEFAULT NULL, 
  `georeferenceProtocol` text DEFAULT NULL, 
  `georeferenceRemarks` text DEFAULT NULL, 
  `georeferenceSources` text DEFAULT NULL, 
  `georeferenceVerificationStatus` text DEFAULT NULL, 
  `habitat` text DEFAULT NULL, 
  `higherClassification` text DEFAULT NULL, 
  `higherGeography` text DEFAULT NULL, 
  `identificationQualifier` text DEFAULT NULL, 
  `identificationReferences` text DEFAULT NULL, 
  `identificationRemarks` text DEFAULT NULL, 
  `identifiedBy` text DEFAULT NULL, 
  `individualCount` text DEFAULT NULL, 
  `infraspecificEpithet` text DEFAULT NULL, 
  `institutionCode` text DEFAULT NULL, 
  `islandGroup` text DEFAULT NULL, 
  `kingdom` text DEFAULT NULL, 
  `language` text DEFAULT NULL, 
  `lifeStage` text DEFAULT NULL, 
  `locality` text DEFAULT NULL, 
  `locationAccordingTo` text DEFAULT NULL, 
  `locationRemarks` text DEFAULT NULL, 
  `maximumElevationInMeters` text DEFAULT NULL, 
  `minimumElevationInMeters` text DEFAULT NULL, 
  `modified` text DEFAULT NULL, 
  `municipality` text DEFAULT NULL, 
  `nomenclaturalCode` text DEFAULT NULL, 
  `occurrenceRemarks` text DEFAULT NULL, 
  `_order` text DEFAULT NULL, 
  `otherCatalogNumbers` text DEFAULT NULL, 
  `ownerInstitutionCode` text DEFAULT NULL, 
  `phylum` text DEFAULT NULL, 
  `preparations` text DEFAULT NULL, 
  `previousIdentifications` text DEFAULT NULL, 
  `recordedBy` text DEFAULT NULL, 
  `recordNumber` text DEFAULT NULL, 
  `_references` text DEFAULT NULL, 
  `reproductiveCondition` text DEFAULT NULL, 
  `rights` text DEFAULT NULL, 
  `rightsHolder` text DEFAULT NULL, 
  `samplingProtocol` text DEFAULT NULL, 
  `scientificName` text DEFAULT NULL, 
  `scientificNameAuthorship` text DEFAULT NULL, 
  `sex` text DEFAULT NULL, 
  `specificEpithet` text DEFAULT NULL, 
  `stateProvince` text DEFAULT NULL, 
  `subgenus` text DEFAULT NULL, 
  `taxonRank` text DEFAULT NULL, 
  `taxonRemarks` text DEFAULT NULL, 
  `_type` text DEFAULT NULL, 
  `typeStatus` text DEFAULT NULL, 
  `verbatimCoordinates` text DEFAULT NULL, 
  `verbatimCoordinateSystem` text DEFAULT NULL, 
  `verbatimDepth` text DEFAULT NULL, 
  `verbatimElevation` text DEFAULT NULL, 
  `verbatimEventDate` text DEFAULT NULL, 
  `verbatimLatitude` text DEFAULT NULL, 
  `verbatimLocality` text DEFAULT NULL, 
  `verbatimLongitude` text DEFAULT NULL, 
  `verbatimSRS` text DEFAULT NULL, 
  `vernacularName` text DEFAULT NULL, 
  `waterBody` text DEFAULT NULL, 
  `year` text DEFAULT NULL, 
PRIMARY KEY `PRIMARY` (`id`),
UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB;