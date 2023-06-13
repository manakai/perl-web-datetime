all:

CURL = curl
WGET = wget
GIT = git

clean: clean-json-ps
	rm -fr local/*.json local/*.txt

updatenightly: clean update-submodules json-ps lib/Web/DateTime/_Defs.pm
	git add lib/Web/DateTime/_Defs.pm

update-submodules: local/bin/pmbp.pl
	$(CURL) https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	git add t_deps/modules
	perl local/bin/pmbp.pl --update
	git add config
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

## ------ Setup ------

PERL = ./perl

deps: git-submodules pmbp-install

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) \
	    --install \
            --create-perl-command-shortcut @perl \
            --create-perl-command-shortcut @prove

## ------ Build ------

json-ps: local/perl-latest/pm/lib/perl5/JSON/PS.pm
clean-json-ps:
	rm -fr local/perl-latest/pm/lib/perl5/JSON/PS.pm
local/perl-latest/pm/lib/perl5/JSON/PS.pm:
	mkdir -p local/perl-latest/pm/lib/perl5/JSON
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-json-ps/master/lib/JSON/PS.pm

lib/Web/DateTime/_Defs.pm: bin/generate-defs.pl \
    local/timezones-mail-names.json local/datetime-seconds.json
	$(PERL) bin/generate-defs.pl > $@
	$(PERL) -c $@

local/timezones-mail-names.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-locale/master/data/timezones/mail-names.json
local/datetime-seconds.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-locale/master/data/datetime/seconds.json

local/jd-g.txt:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-locale/master/data/calendar/map-jd-gregorian.txt
local/jd-j.txt:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-locale/master/data/calendar/map-jd-julian.txt

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps local/jd-g.txt local/jd-j.txt

test-main:
	$(PROVE) t/*.t

## License: Public Domain.
