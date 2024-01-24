CC=g++
PREFIX ?= /usr
DATADIR= $(PREFIX)/share
SCRIPTS_DIR=$(CURDIR)/scripts
PKG_DATA_DIR=$(CURDIR)/data
TZDB_DIR=$(CURDIR)/iana.org
SRC_DIR=$(CURDIR)/src
BUILD_DIR=$(CURDIR)/build
INSTALL_DIR=$(DATADIR)/tzdata-timed
DESTDIR ?=

all: prepare-timed-data

createdirs:
	rm -rf $(BUILD_DIR) $(SRC_DIR)
	mkdir $(BUILD_DIR) $(SRC_DIR)

# Compile helper binary for calculating custom signatures for
# compiled time zone information files.
signature: createdirs
	$(CC) $(SCRIPTS_DIR)/signature.c++ -Wall -Werror -xc++ -o $(BUILD_DIR)/signature

# Create time zones according to ISO 8601.
iso8601zones: createdirs
	$(SCRIPTS_DIR)/iso8601.perl > $(BUILD_DIR)/iso8601

# Extract and uncompress the tz database source package.
tzsources: createdirs
	tar -C $(SRC_DIR) -xzf $(lastword $(wildcard $(TZDB_DIR)/tzdata*.tar.gz))

# Build the tz database without links (aliases between timezones),
# and with custom ISO 8601 zones, exclude zones defined in etcetera,
# factory, systemv, backward solar87, solar88, solar89.
# Create a list of time zones without links, store in file zone.list.
list-zones-without-links: tzsources iso8601zones
	$(SCRIPTS_DIR)/zone-list.sh $(SRC_DIR) $(BUILD_DIR) > $(BUILD_DIR)/zone.list

# Build the complete tz database with links, and add custom ISO 8601 zones
# Create a list of time zones that are links, store in file zone.link
# Calculate md5 sums for the time zones, store in file md5sums
# Calculate custom signatures for the time zones with the signature program,
# store in file signatures.
process-zones: tzsources signature iso8601zones
	$(SCRIPTS_DIR)/zone-generate.sh $(SRC_DIR) $(BUILD_DIR)

# Create a list of all time zone main names and aliases (if any). See
# find-aliases.perl for documentation.
find-aliases: process-zones list-zones-without-links
	perl -w -s $(SCRIPTS_DIR)/find-aliases.perl \
	-zones=$(BUILD_DIR)/zone.list -signatures=$(BUILD_DIR)/signatures \
	-md5sum=$(BUILD_DIR)/md5sum -links=$(BUILD_DIR)/zone.link \
	-zonetab=/usr/share/zoneinfo/zone.tab > $(BUILD_DIR)/zone.alias

prepare-timed-data: find-aliases
	$(SCRIPTS_DIR)/prepare-timed-data.perl \
	--zonetab=$(SRC_DIR)/zone.tab \
	--signatures=$(BUILD_DIR)/signatures \
	--mcc-main=$(PKG_DATA_DIR)/MCC \
	--mcc-skip-patterns=$(PKG_DATA_DIR)/MCC-unsupported-zones \
	--distinct=$(PKG_DATA_DIR)/distinct.tab \
	--single=$(PKG_DATA_DIR)/single.tab \
	--single-output=$(BUILD_DIR)/single.data \
	--distinct-output=$(BUILD_DIR)/distinct.data \
	--full-output=$(BUILD_DIR)/olson.data \
	--country-by-mcc-output=$(BUILD_DIR)/country-by-mcc.data \
	--zones-by-country-output=$(BUILD_DIR)/zones-by-country.data

install:
	mkdir -p $(DESTDIR)$(INSTALL_DIR)
	cp $(BUILD_DIR)/country-by-mcc.data $(DESTDIR)$(INSTALL_DIR)
	cp $(BUILD_DIR)/single.data $(DESTDIR)$(INSTALL_DIR)
	cp $(BUILD_DIR)/zones-by-country.data $(DESTDIR)$(INSTALL_DIR)
	cp $(BUILD_DIR)/zone.alias $(DESTDIR)$(INSTALL_DIR)

clean:
	rm -rf $(SRC_DIR) $(BUILD_DIR)
