#!/bin/bash
echo "1..2"
rootdir=$(cd `dirname $0`/.. && pwd)

$rootdir/perl -MWeb::DateTime -e 'printf "%s\t%s\n", $_, Web::DateTime->new_from_jd($_)->to_julian_ymd_string for 1000000..2525000' > $rootdir/local/julian-days.txt

(diff -u $rootdir/local/jd-j.txt $rootdir/local/julian-days.txt && echo "ok 1") || echo "not ok 1"

$rootdir/perl -MWeb::DateTime::Parser -n -e 'if (/^(\S+)\t(\S+)$/) { $dt = Web::DateTime::Parser->parse_julian_ymd_string($2); $jd = $dt->to_jd + 0.5; print "$jd\t$2\n" }' < $rootdir/local/julian-days.txt > $rootdir/local/julian-days-2.txt

(diff -u $rootdir/local/jd-j.txt $rootdir/local/julian-days-2.txt && echo "ok 2") || echo "not ok 2"

## License: Public Domain.
