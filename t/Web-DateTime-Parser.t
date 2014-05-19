use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Differences;
use Web::DateTime::Parser;

for my $test (
  ['', undef,
   [{type => 'date:syntax error', level => 'm'}]],
  ['2012-1-1', undef,
   [{type => 'date:syntax error', level => 'm'}]],
  ['2012-01-02', '2012-01-02'],
  ['2012-01-31', '2012-01-31'],
  ['2012-02-29', '2012-02-29'],
  ['2012-01-32', undef,
   [{type => 'datetime:bad day', value => '32', level => 'm'}]],
  ['2011-02-29', undef,
   [{type => 'datetime:bad day', value => '29', level => 'm'}]],
  ['2011-02-00', undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['2011-00-29', undef,
   [{type => 'datetime:bad month', value => '00', level => 'm'}]],
  ['2011-13-29', undef,
   [{type => 'datetime:bad month', value => '13', level => 'm'}]],
  ['+02011-03-29', '2011-03-29',
   [{type => 'datetime:expanded year', value => '+02011', level => 'w'}]],
  ['1500-03-29', '1500-03-29',
   [{type => 'datetime:pre-gregorio year', value => '1500', level => 'w'}]],
  ['2500-03', '2500-03-01'],
  ['2500', '2500-01-01'],
  ['25', '2500-01-01'],
  ['+2500-03', '2500-03-01',
   [{type => 'datetime:expanded year', value => '+2500', level => 'w'}]],
  ['+2500', '2500-01-01',
   [{type => 'datetime:expanded year', value => '+2500', level => 'w'}]],
  ['+125', '12500-01-01',
   [{type => 'datetime:expanded year', value => '+12500', level => 'w'}]],
  ['2012-W04-3' => '2012-01-25'],
  ['2013-W01-1' => '2012-12-31'],
  ['2013-W01-7' => '2013-01-06'],
  ['2013-W01-0' => undef,
   [{type => 'datetime:bad day', value => '0', level => 'm'}]],
  ['2013-W01-8' => undef,
   [{type => 'datetime:bad day', value => '8', level => 'm'}]],
  ['2013-W00-2' => undef,
   [{type => 'week:bad week', value => '00', level => 'm'}]],
  ['2012-W53-2' => undef,
   [{type => 'week:bad week', value => '53', level => 'm'}]],
  ['2004-W53-2' => '2004-12-28'],
  ['+2004-W53-2' => '2004-12-28',
   [{type => 'datetime:expanded year', value => '+2004', level => 'w'}]],
  ['2004-W53' => '2004-12-27'],
  ['2004-W01' => '2003-12-29'],
  ['+2004-W01' => '2003-12-29',
   [{type => 'datetime:expanded year', value => '+2004', level => 'w'}]],
  ['2012-W53' => undef,
   [{type => 'week:bad week', value => '53', level => 'm'}]],
  ['2021-031' => '2021-01-31'],
  ['2021-365' => '2021-12-31'],
  ['+02021-365' => '2021-12-31',
   [{type => 'datetime:expanded year', value => '+02021', level => 'w'}]],
  ['2021-366' => undef,
   [{type => 'datetime:bad day', value => '366', level => 'm'}]],
  ['2021-000' => undef,
   [{type => 'datetime:bad day', value => '000', level => 'm'}]],
  ['20100204' => '2010-02-04'],
  ['201002' => '2010-02-01'],
  ['+020100303' => '2010-03-03',
   [{type => 'datetime:expanded year', value => '+02010', level => 'w'}]],
  ['2010W041' => '2010-01-25'],
  ['2010W03' => '2010-01-18'],
  ['2008004' => '2008-01-04'],
  ["2010\x{2010}05\x{2010}03" => '2010-05-03',
   [{type => 'datetime:hyphen', level => 'w'}]],
  ["2010\x{2212}05\x{2212}03" => undef,
   [{type => 'datetime:minus sign', level => 'w'},
    {type => 'date:syntax error', level => 'm'}]],
  ["2010-w04-3" => '2010-01-27',
   [{type => 'datetime:lowercase designator', value => 'w', level => 'w'}]],
  ["2010-w04" => '2010-01-25',
   [{type => 'datetime:lowercase designator', value => 'w', level => 'w'}]],
  ["2010w043" => '2010-01-27',
   [{type => 'datetime:lowercase designator', value => 'w', level => 'w'}]],
  ["2010w04" => '2010-01-25',
   [{type => 'datetime:lowercase designator', value => 'w', level => 'w'}]],
  ["2010-w043" => undef,
   [{type => 'datetime:lowercase designator', value => 'w', level => 'w'},
    {type => 'date:syntax error', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_iso8601_date_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_date_string, $test->[1];
      is $dt && $dt->time_zone, undef;
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[2] || [];
    done $c;
  } n => 4, name => ['parse_iso8601_date_string'];
}

for my $test (
  ['Z', 0],
  ['+00:00', 0],
  ['-00:12', -12*60],
  ['+03:12', 3*60*60+12*60],
  ['-13:12', -(13*60*60+12*60)],
  ['-00:00', 0, [{type => 'datetime:-00:00', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_time_zone_offset_string ($test->[0]);
    isa_ok $tz, 'Web::DateTime::TimeZone';
    is $tz->offset_as_seconds, $test->[1];
    eq_or_diff \@error, $test->[2] || [];
    done $c;
  } n => 3;
}

for my $test (
  [''],
  ['z'],
  ['+0000'],
  ['12:00'],
  ['+24:00', [{type => 'datetime:bad timezone hour', level => 'm', value => 24}]],
  ['-24:00', [{type => 'datetime:bad timezone hour', level => 'm', value => 24}]],
  ['+20:60', [{type => 'datetime:bad timezone minute', level => 'm', value => 60}]],
  ['+20:600'],
  ['+200:60'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_time_zone_offset_string ($test->[0]);
    is $tz, undef;
    eq_or_diff \@error, $test->[1] || [{type => 'tz:syntax error', level => 'm'}];
    done $c;
  } n => 2;
}

for my $test (
  [''],
  ['z'],
  ['1000.0'],
  ['0000', [{type => 'datetime:bad year', level => 'm', value => '0000'}]],
  ['2010-01'],
  ['H20'],
  ['20.01'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_year_string ($test->[0]);
    is $tz, undef;
    eq_or_diff \@error, $test->[1] || [{type => 'year:syntax error', level => 'm'}];
    done $c;
  } n => 2;
}

for my $test (
  [''],
  ['z'],
  ['1000.0'],
  ['2010-01'],
  ['01-00', [{type => 'datetime:bad day', level => 'm', value => '00'}]],
  ['01-32', [{type => 'datetime:bad day', level => 'm', value => '32'}]],
  ['02-30', [{type => 'datetime:bad day', level => 'm', value => '30'}]],
  ['00-30', [{type => 'datetime:bad month', level => 'm', value => '00'}]],
  ['13-30', [{type => 'datetime:bad month', level => 'm', value => '13'}]],
  ['001-30'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_yearless_date_string ($test->[0]);
    is $tz, undef;
    eq_or_diff \@error, $test->[1] || [{type => 'date:syntax error', level => 'm'}];
    done $c;
  } n => 2;
}

for my $test (
  ['2012-03-02T00:12:00', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-02T00:12:00Z', '2012-03-02T00:12:00Z', 'Z'],
  ['2012-03-02T00:12:00+04:00', '2012-03-01T20:12:00Z', '+04:00'],
  ['', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2021-02-03', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-01T12:00Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01 00:23:11Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T01:23:12.1222', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T01:23:12.1222Z', '2012-04-01T01:23:12.1222Z', 'Z'],
  ['2012-03-04T00:12:44-00', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-05-04T00:12:01-00:00', '2012-05-04T00:12:01Z', undef],
  ['2012-05-04T00:12:01-00:30', '2012-05-04T00:42:01Z', '-00:30'],
  ['02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['12012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['+02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['-02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T00:23:60Z', undef, undef,
   [{type => 'datetime:bad second', value => '60', level => 'm'}]],
  ['2012-04-01T00:60:23Z', undef, undef,
   [{type => 'datetime:bad minute', value => '60', level => 'm'}]],
  ['2012-04-01T60:23:00Z', undef, undef,
   [{type => 'datetime:bad hour', value => '60', level => 'm'}]],
  ['2012-04-00T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['2012-04-31T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '31', level => 'm'}]],
  ['2012-00-01T00:23:00Z', undef, undef,
   [{type => 'datetime:bad month', value => '00', level => 'm'}]],
  ['2012-02-29T00:23:00Z', '2012-02-29T00:23:00Z', 'Z'],
  ['2011-02-29T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '29', level => 'm'}]],
  ['2012-02-29t00:23:00Z', '2012-02-29T00:23:00Z', 'Z',
   [{type => 'datetime:lowercase designator', value => 't', level => 's'}],
   [{type => 'datetime:lowercase designator', value => 't', level => 'm'}]],
  ['2012-02-29T00:23:00z', '2012-02-29T00:23:00Z', 'Z',
   [{type => 'datetime:lowercase designator', value => 'z', level => 's'}],
   [{type => 'datetime:lowercase designator', value => 'z', level => 'm'}]],
  ['2012-02-29T00:23:00+13:59', '2012-02-28T10:24:00Z', '+13:59'],
  ['2012-02-29T00:23:00+14:00', '2012-02-28T10:23:00Z', '+14:00'],
  ['2012-02-29T00:23:00+14:01', '2012-02-28T10:22:00Z', '+14:01',
   [],
   [{type => 'datetime:bad timezone hour', value => '+14', level => 'm'}]],
  ['2012-02-29T00:23:00-13:59', '2012-02-29T14:22:00Z', '-13:59'],
  ['2012-02-29T00:23:00-14:00', '2012-02-29T14:23:00Z', '-14:00'],
  ['2012-02-29T00:23:00-14:01', '2012-02-29T14:24:00Z', '-14:01',
   [],
   [{type => 'datetime:bad timezone hour', value => '-14', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_rfc3339_date_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt && $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_rfc3339_date_time_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_rfc3339_xs_date_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt && $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[4] || $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_rfc3339_xs_date_time_string', $test->[0]];
}

for my $test (
  ['Mon, 19 May 2014 02:12:01 GMT', '2014-05-19T02:12:01Z'],
  ['moN, 19 mAY 2014 02:12:01 gmt', '2014-05-19T02:12:01Z'],
  ['Mon, 19 May 2014 02:12:01', '2014-05-19T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Mon, 19 May 14 02:12:01 GMT', '2014-05-19T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Thu, 19 May 94 02:12:01 GMT', '1994-05-19T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 9 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 009 May 2014 02:12:01 GMT', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 9 May 02014 02:12:01 GMT', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09 May 1600 02:12:01 GMT', undef,
   [{type => 'datetime:bad year', value => 1600, level => 'w'}]],
  ['Fri,  09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri,09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09 May 2014 02:12:01 +0000', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09 May 2014 02:12:01 -0000', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09May 2014 02:12:01 GMT', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09-May-2014 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['9-May-14 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09 May 2014 02:12:01 GMT?', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['  Mon, 09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Sun, 09 March 2014 02:12:01 GMT', '2014-03-09T02:12:01Z',
   [{type => 'datetime:bad month', value => 'March', level => 'm'}]],
  ['Mon, 09 nov 1801 02:12:01 GMT', '1801-11-09T02:12:01Z'],
  ['Wed, 09 DEC 3801 02:12:01 GMT', '3801-12-09T02:12:01Z'],
  ['Mon, 29 Feb 2013 02:12:01 GMT', undef,
   [{type => 'datetime:bad day', value => 29, level => 'm'}]],
  ['Tue, 29 Feb 2000 02:12:01 GMT', '2000-02-29T02:12:01Z'],
  ['Tue, 29 Feb 2013 02:12:01 GMT', undef,
   [{type => 'datetime:bad day', value => 29, level => 'm'}]],
  ['Mon, 00 Feb 2013 02:12:01 GMT', undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['Mon, 01 Feb 2013 24:00:00 GMT', undef,
   [{type => 'datetime:bad hour', value => '24', level => 'm'}]],
  ['Mon, 01 Feb 2013 00:60:00 GMT', undef,
   [{type => 'datetime:bad minute', value => '60', level => 'm'}]],
  ['Mon, 01 Feb 2013 00:00:60 GMT', undef,
   [{type => 'datetime:bad second', value => '60', level => 'm'}]],
  ['Sat, 09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z',
   [{type => 'datetime:bad weekday', value => 'Sat',
     text => 'Fri', level => 'm'}]],
  ['Sat, 31 Jan 2014 02:12:01 GMT', '2014-01-31T02:12:01Z',
   [{type => 'datetime:bad weekday', value => 'Sat',
     text => 'Fri', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_http_date_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      is $dt && $dt->time_zone && $dt->time_zone->to_offset_string, 'Z';
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[2] || [];
    done $c;
  } n => 4, name => ['parse_http_date_string', $test->[0]];
}

for my $test (
  ['Mon, 19 May 2014 02:12:01 GMT', '2014-05-19T02:12:01Z', 'Z'],
  ['moN, 19 mAY 2014 02:12:01 gmt', '2014-05-19T02:12:01Z', 'Z',
   [{type => 'datetime:month:bad case', value => 'mAY', level => 's'},
    {type => 'datetime:tz:bad case', value => 'gmt', level => 's'},
    {type => 'datetime:weekday:bad case', value => 'moN', level => 's'}]],
  ['Mon, 19 May 2014 02:12:01', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Mon, 19 May 14 02:12:01 GMT', '2014-05-19T02:12:01Z', 'Z',
   [{type => 'datetime:bad year', value => '14', level => 's'}]],
  ['Thu, 19 May 94 02:12:01 GMT', '1994-05-19T02:12:01Z', 'Z',
   [{type => 'datetime:bad year', value => '94', level => 's'}]],
  ['Wed, 19 May 49 02:12:01 GMT', '2049-05-19T02:12:01Z', 'Z',
   [{type => 'datetime:bad year', value => '49', level => 's'}]],
  ['Fri, 19 May 50 02:12:01 GMT', '1950-05-19T02:12:01Z', 'Z',
   [{type => 'datetime:bad year', value => '50', level => 's'}]],
  ['Sat, 19 May 101 02:12:01 GMT', '2001-05-19T02:12:01Z', 'Z',
   [{type => 'datetime:bad year', value => '101', level => 'm'}]],
  ['Sun, 19 May 19101 02:12:01 GMT', '19101-05-19T02:12:01Z', 'Z',
   [{type => 'datetime:bad year', value => '19101', level => 'm'}]],
  ['Fri, 9 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z'],
  ['Fri, 009 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z',
   [{type => 'datetime:bad day', value => '009', level => 'm'}]],
  ['Fri, 9 May 02014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z',
   [{type => 'datetime:bad year', value => '02014', level => 'm'}]],
  ['Tue, 09 May 1600 02:12:01 GMT', '1600-05-09T02:12:01Z', 'Z'],
  ['Fri,  09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => '  ', level => 's'}]],
  ['Fri,09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z'],
  ['09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z'],
  ['Fri, 09 May 2014 02:12:01 +0000', '2014-05-09T02:12:01Z', 'Z'],
  ['Fri, 09 May 2014 02:12:01 -0000', '2014-05-09T02:12:01Z', 'Z'],
  ['Fri, 09May 2014 02:12:01 GMT', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09-May-2014 02:12:01 GMT', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['9-May-14 02:12:01 GMT', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri, 09 May 2014 02:12:01 GMT?', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['  Mon, 09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => '  ', level => 's'},
    {type => 'datetime:bad weekday', value => 'Mon', text => 'Fri',
     level => 'm'}]],
  ['Sun, 09 March 2014 02:12:01 GMT', undef, undef,
   [{type => 'datetime:bad month', value => 'March', level => 'm'}]],
  ['Mon, 09 nov 1801 02:12:01 GMT', '1801-11-09T02:12:01Z', 'Z',
   [{type => 'datetime:month:bad case', value => 'nov', level => 's'}]],
  ['Wed, 09 DEC 3801 02:12:01 GMT', '3801-12-09T02:12:01Z', 'Z',
   [{type => 'datetime:month:bad case', value => 'DEC', level => 's'}]],
  ['Mon, 29 Feb 2013 02:12:01 GMT', undef, undef,
   [{type => 'datetime:bad day', value => 29, level => 'm'}]],
  ['Tue, 29 Feb 2000 02:12:01 GMT', '2000-02-29T02:12:01Z', 'Z'],
  ['Tue, 29 Feb 2013 02:12:01 GMT', undef, undef,
   [{type => 'datetime:bad day', value => 29, level => 'm'}]],
  ['Mon, 00 Feb 2013 02:12:01 GMT', undef, undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['Mon, 01 Feb 2013 24:00:00 GMT', undef, undef,
   [{type => 'datetime:bad hour', value => '24', level => 'm'}]],
  ['Mon, 01 Feb 2013 00:60:00 GMT', undef, undef,
   [{type => 'datetime:bad minute', value => '60', level => 'm'}]],
  ['Mon, 01 Feb 2013 00:00:60 GMT', undef, undef,
   [{type => 'datetime:bad second', value => '60', level => 'm'}]],
  ['Sat, 09 May 2014 02:12:01 GMT', '2014-05-09T02:12:01Z', 'Z',
   [{type => 'datetime:bad weekday', value => 'Sat',
     text => 'Fri', level => 'm'}]],
  ['Sat, 31 Jan 2014 02:12:01 GMT', '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad weekday', value => 'Sat',
     text => 'Fri', level => 'm'}]],
  ['Fri,(aa) 31 Jan 2014 02:12:01 GMT', '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => '(aa) ', level => 's'}]],
  ['Fri,(a\za) 31 Jan 2014 02:12:01 GMT', '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => '(a\za) ', level => 's'}]],
  ['Fri,((aa)) 31 Jan 2014 02:12:01 GMT', '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => '((aa)) ', level => 's'}]],
  ['Fri,(((aa))) 31 Jan 2014 02:12:01 GMT', '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => '(((aa))) ', level => 's'}]],
  ['Fri,((aa) 31 Jan 2014 02:12:01 GMT', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['Fri,((aa)\)) 31 Jan 2014 02:12:01 GMT', '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => '((aa)\)) ', level => 's'}]],
  ["Fri,((aa)\x00) 31 Jan 2014 02:12:01 GMT", '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => "((aa)\x00) ", level => 's'}]],
  ["Fri,((aa)\x80) 31 Jan 2014 02:12:01 GMT", '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:syntax error', value => "((aa)\x80) ", level => 'm'}]],
  ["Fri,((aa)\x{FFFF}) 31 Jan 2014 02:12:01 GMT", '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:syntax error', value => "((aa)\x{FFFF}) ", level => 'm'}]],
  ["Fri, 31 Jan 2014 02\x0D\x0A:12:01 GMT", '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:syntax error', value => "\x0D\x0A", level => 'm'}]],
  ["Fri, 31 Jan 2014 02\x0D\x0A :12:01 GMT", '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => "\x0D\x0A ", level => 's'}]],
  ["Fri, 31 Jan 2014 02\x0D\x0A\x09:12:01 GMT", '2014-01-31T02:12:01Z', 'Z',
   [{type => 'datetime:bad CFWS', value => "\x0D\x0A\x09", level => 's'}]],
  ['Fri, 31 Jan 2014 02:12:01 -0360', undef, undef,
   [{type => 'datetime:bad timezone minute', value => '60', level => 'm'}]],
  ['Fri, 31 Jan 2014 02:12:01 -9950', '2014-02-04T06:02:01Z', '-99:50'],
  ['Fri, 31 Jan 2014 02:12:01 Z', '2014-01-31T02:12:01Z', undef,
   [{type => 'datetime:tzname', value => 'Z', level => 'w'}]],
  ['Fri, 31 Jan 2014 02:12:01 S', '2014-01-31T02:12:01Z', undef,
   [{type => 'datetime:tzname', value => 'S', level => 'w'}]],
  ['Fri, 31 Jan 2014 02:12:01 J', '2014-01-31T02:12:01Z', undef,
   [{type => 'datetime:tzname', value => 'J', level => 'm'}]],
  ['Fri, 31 Jan 2014 02:12:01 HOGE', '2014-01-31T02:12:01Z', undef,
   [{type => 'datetime:tzname', value => 'HOGE', level => 'm'}]],
  ['Fri, 31 Jan 2014 02:12:01 EST', '2014-01-31T07:12:01Z', '-05:00',
   [{type => 'datetime:tzname', value => 'EST', level => 'w'}]],
  ['Fri, 31 Jan 2014 02:12:01 JST', '2014-01-30T17:12:01Z', '+09:00',
   [{type => 'datetime:tzname', value => 'JST', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_rss2_date_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt && $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_rss2_date_time_string', $test->[0]];
}

for my $test (
  ['2012-03-02T00:12:00', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-02T00:12:00Z', '2012-03-02T00:12:00Z', 'Z'],
  ['2012-03-02T00:12:00+04:00', '2012-03-01T20:12:00Z', '+04:00'],
  ['', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-03T12', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-03T12Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2021', '2021-01-01T00:00:00Z', 'Z'],
  ['2021-02', '2021-02-01T00:00:00Z', 'Z'],
  ['2021-02-03', '2021-02-03T00:00:00Z', 'Z'],
  ['2012-03-01T12:00Z', '2012-03-01T12:00:00Z', 'Z'],
  ['2012-04-01 00:23:11Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T01:23:12.1222', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T01:23:12.1222Z', '2012-04-01T01:23:12.1222Z', 'Z'],
  ['2012-03-04T00:12:44-00', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-05-04T00:12:01-00:00', '2012-05-04T00:12:01Z', 'Z'],
  ['2012-05-04T00:12:01-00:30', '2012-05-04T00:42:01Z', '-00:30'],
  ['02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['12012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['+02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['-02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T00:23:60Z', undef, undef,
   [{type => 'datetime:bad second', value => '60', level => 'm'}]],
  ['2012-04-01T00:60:23Z', undef, undef,
   [{type => 'datetime:bad minute', value => '60', level => 'm'}]],
  ['2012-04-01T60:23:00Z', undef, undef,
   [{type => 'datetime:bad hour', value => '60', level => 'm'}]],
  ['2012-04-00T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['2012-04-31T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '31', level => 'm'}]],
  ['2012-00-01T00:23:00Z', undef, undef,
   [{type => 'datetime:bad month', value => '00', level => 'm'}]],
  ['2012-02-29T00:23:00Z', '2012-02-29T00:23:00Z', 'Z'],
  ['2011-02-29T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '29', level => 'm'}]],
  ['2012-02-29t00:23:00Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-02-29T00:23:00z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-02-29T00:23:00+13:59', '2012-02-28T10:24:00Z', '+13:59'],
  ['2012-02-29T00:23:00+14:00', '2012-02-28T10:23:00Z', '+14:00'],
  ['2012-02-29T00:23:00+14:01', '2012-02-28T10:22:00Z', '+14:01'],
  ['2012-02-29T00:23:00-13:59', '2012-02-29T14:22:00Z', '-13:59'],
  ['2012-02-29T00:23:00-14:00', '2012-02-29T14:23:00Z', '-14:00'],
  ['2012-02-29T00:23:00-14:01', '2012-02-29T14:24:00Z', '-14:01'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_w3c_dtf_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt && $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_w3c_dtf_string', $test->[0]];
}

for my $test (
  ['2012-03-02T00:12:00', '2012-03-02T00:12:00Z', undef],
  ['2012-03-02T00:12:00Z', '2012-03-02T00:12:00Z', 'Z'],
  ['2012-03-02T00:12:00+04:00', '2012-03-01T20:12:00Z', '+04:00'],
  ['', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2021-02-03', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-01T12:00', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01 00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T01:23:12.1222', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-04T00:12:44-00', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-05-04T00:12:01-00:00', '2012-05-04T00:12:01Z', 'Z',
   [{type => 'datetime:-00:00', level => 'm'}]],
  ['2012-05-04T00:12:01-00:30', '2012-05-04T00:42:01Z', '-00:30'],
  ['02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['12012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['+02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['-02012-04-01T00:23:11', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T00:23:60', undef, undef,
   [{type => 'datetime:bad second', value => '60', level => 'm'}]],
  ['2012-04-01T00:60:23', undef, undef,
   [{type => 'datetime:bad minute', value => '60', level => 'm'}]],
  ['2012-04-01T60:23:00', undef, undef,
   [{type => 'datetime:bad hour', value => '60', level => 'm'}]],
  ['2012-04-00T00:23:00', undef, undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['2012-04-31T00:23:00', undef, undef,
   [{type => 'datetime:bad day', value => '31', level => 'm'}]],
  ['2012-00-01T00:23:00', undef, undef,
   [{type => 'datetime:bad month', value => '00', level => 'm'}]],
  ['2012-02-29T00:23:00', '2012-02-29T00:23:00Z', undef],
  ['2011-02-29T00:23:00', undef, undef,
   [{type => 'datetime:bad day', value => '29', level => 'm'}]],
  ['1400-02-23T00:23:00', '1400-02-23T00:23:00Z', undef,
   [{type => 'datetime:pre-gregorio year', value => '1400', level => 'w'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_schema_org_date_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt && $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_schema_org_date_time_string'];
}

for my $test (
  ['2012-03-02T00:12:00', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-02T00:12:00Z', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-02T00:12:00+04:00', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2021-02-03', '2021-02-03T00:00:00Z'],
  ['2012-03-01T12:00', '2012-03-01T12:00:00Z'],
  ['2012-04-01 00:23', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T01:23:12.1222', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-04-01T01:23.1222', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['+02012-04-01T00:11', '2012-04-01T00:11:00Z',
   [{type => 'datetime:expanded year', value => '+02012', level => 'w'}]],
  ['2012-04-01T00:60', undef,
   [{type => 'datetime:bad minute', value => '60', level => 'm'}]],
  ['2012-04-01T60:23', undef,
   [{type => 'datetime:bad hour', value => '60', level => 'm'}]],
  ['2012-04-00T00:23', undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['2012-04-31T00:23', undef,
   [{type => 'datetime:bad day', value => '31', level => 'm'}]],
  ['2012-04-31', undef,
   [{type => 'datetime:bad day', value => '31', level => 'm'}]],
  ['2012-00-01T00:23', undef,
   [{type => 'datetime:bad month', value => '00', level => 'm'}]],
  ['2012-02-29T00:23', '2012-02-29T00:23:00Z'],
  ['2011-02-29T00:23', undef,
   [{type => 'datetime:bad day', value => '29', level => 'm'}]],
  ['1400-02-23T00:23', '1400-02-23T00:23:00Z',
   [{type => 'datetime:pre-gregorio year', value => '1400', level => 'w'}]],
  ['2012-03-01t12:00', '2012-03-01T12:00:00Z',
   [{type => 'datetime:lowercase designator', value => 't', level => 'w'}]],
  ["2012\x{2010}03\x{2010}01T12:00", '2012-03-01T12:00:00Z',
   [{type => 'datetime:hyphen', level => 'w'}]],
  ['2400-02-2300:23', '2400-02-23T00:23:00Z'],
  ['24000223T0023', '2400-02-23T00:23:00Z'],
  ['240002230023', '2400-02-23T00:23:00Z'],
  ['2012-04-01T0123', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_ogp_date_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      is $dt && $dt->time_zone, undef;
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[2] || [];
    done $c;
  } n => 4, name => ['parse_ogp_date_time_string', $test->[0]];
}

for my $test (
  ['2012-03-02T00:12:00', '2012-03-02T00:12:00Z', undef],
  ['2012-03-02T00:12:00Z', '2012-03-02T00:12:00Z', 'Z'],
  ['2012-03-02T00:12:00+04:00', '2012-03-01T20:12:00Z', '+04:00'],
  ['', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-03T12', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03-03T12Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-03Z', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2021', '2021-01-01T00:00:00Z', undef],
  ['2021-02', '2021-02-01T00:00:00Z', undef],
  ['2021-02-03', '2021-02-03T00:00:00Z', undef],
  ['2012-03-01T12:00Z', '2012-03-01T12:00:00Z', 'Z'],
  ['2012-04-01 00:23:11Z', '2012-04-01T00:23:11Z', 'Z'],
  ['2012-04-01T01:23:12.1222', '2012-04-01T01:23:12.1222Z', undef],
  ['2012-04-01T01:23:12.1222Z', '2012-04-01T01:23:12.1222Z', 'Z'],
  ['2012-03-04T00:12:44-00', undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-05-04T00:12:01-00:00', '2012-05-04T00:12:01Z', 'Z',
   [{type => 'datetime:-00:00', level => 'm'}]],
  ['2012-05-04T00:12:01-00:30', '2012-05-04T00:42:01Z', '-00:30'],
  ['02012-04-01T00:23:11', '2012-04-01T00:23:11Z', undef],
  ['12012-04-01T00:23:11', '12012-04-01T00:23:11Z', undef],
  ['+02012-04-01T00:23:11', '2012-04-01T00:23:11Z', undef],
  ['2012-04-01T00:23:60Z', undef, undef,
   [{type => 'datetime:bad second', value => '60', level => 'm'}]],
  ['2012-04-01T00:60:23Z', undef, undef,
   [{type => 'datetime:bad minute', value => '60', level => 'm'}]],
  ['2012-04-01T60:23:00Z', undef, undef,
   [{type => 'datetime:bad hour', value => '60', level => 'm'}]],
  ['2012-04-00T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '00', level => 'm'}]],
  ['2012-04-31T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '31', level => 'm'}]],
  ['2012-00-01T00:23:00Z', undef, undef,
   [{type => 'datetime:bad month', value => '00', level => 'm'}]],
  ['2012-02-29T00:23:00Z', '2012-02-29T00:23:00Z', 'Z'],
  ['2011-02-29T00:23:00Z', undef, undef,
   [{type => 'datetime:bad day', value => '29', level => 'm'}]],
  ['2012-02-29t00:23:00Z', '2012-02-29T00:23:00Z', 'Z'],
  ['2012-02-29T00:23:00z', '2012-02-29T00:23:00Z', 'Z'],
  ['2012-02-29T00:23:00+13:59', '2012-02-28T10:24:00Z', '+13:59'],
  ['2012-02-29T00:23:00+14:00', '2012-02-28T10:23:00Z', '+14:00'],
  ['2012-02-29T00:23:00+14:01', '2012-02-28T10:22:00Z', '+14:01'],
  ['2012-02-29T00:23:00-13:59', '2012-02-29T14:22:00Z', '-13:59'],
  ['2012-02-29T00:23:00-1359', '2012-02-29T14:22:00Z', '-13:59'],
  ['2012-02-29T00:23:00-14:00', '2012-02-29T14:23:00Z', '-14:00'],
  ['2012-02-29T00:23:00-14:01', '2012-02-29T14:24:00Z', '-14:01'],
  ['2001/06/12', '2001-06-12T00:00:00Z', undef],
  ['2001/6/12', '2001-06-12T00:00:00Z', undef],
  ['2001/06/12 12:34', '2001-06-12T12:34:00Z', undef],
  ['2001/06/12 12:34:56', '2001-06-12T12:34:56Z', undef],
  ['2001/06/12 12:34:56.789', '2001-06-12T12:34:56.789Z', undef],
  ['2001/06/12 12:34:56.7891', '2001-06-12T12:34:56.7891Z', undef],
  ['07/02/2001', '2001-07-02T00:00:00Z', undef],
  ['7/2/2001', '2001-07-02T00:00:00Z', undef],
  ['7/2/2001 12:34', '2001-07-02T12:34:00Z', undef],
  ['7/2/2001 12:34:21', '2001-07-02T12:34:21Z', undef],
  ['07/02/2001 12:34:21', '2001-07-02T12:34:21Z', undef],
  ['2001-7-12', '2001-07-12T00:00:00Z', undef],
  ['2001-7-12 12:3', '2001-07-12T12:03:00Z', undef],
  ['1-1-2012', '2012-01-01T00:00:00Z', undef],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_js_date_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt && $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_js_date_time_string', $test->[0]];
}

for my $test (
  ['', undef, undef, undef],
  ['z', undef, undef, undef],
  ['1000.0', undef, undef, undef],
  ['-41s', 41, 0, -1,
   undef,
   undef,
   [{type => 'duration:html duration', level => 'm'}]],
  ['-PT31H31M', 31*60*60+31*60, 0, -1,
   undef,
   undef,
   undef,
   undef,
   [{type => 'duration:syntax error', value => 'PTHM', level => 'm'}]],
  ['41s' => 41, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ["10m\t30s" => 10*60+30, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['420.400 s' => 420.4, 0, +1,
   undef,
   [{type => 'datetime:fractional second', level => 'm'},
    {type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  [' PT132S', 132, 0, +1,
   [{type => 'duration:space', level => 'm'}],
   undef,
   undef,
   undef,
   [{type => 'duration:space', level => 'm'},
    {type => 'duration:syntax error', value => 'PTS', level => 'm'}]],
  ['32w21d' => 32*7*24*60*60+21*24*60*60, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['0h' => 0, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['42.44m' => undef, undef, undef],
  ['332.000s' => 332, 0, +1,
   undef,
   [{type => 'datetime:fractional second', level => 'm'},
    {type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['32Y32M' => 0, 32*12+32, +1,
   [{type => 'duration:syntax error', value => 'YM', level => 'm'},
    {type => 'duration:months', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'},
    {type => 'duration:months', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'},
    {type => 'duration:months', level => 'm'}]],
  ['32M' => 32*60, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['T32M' => 32*60, 0, +1,
   [{type => 'duration:syntax error', level => 'm',
     value => 'TM'}]],
  ['0Y32M' => 0, 32, +1,
   [{type => 'duration:syntax error', value => 'YM', level => 'm'},
    {type => 'duration:months', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'},
    {type => 'duration:months', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'},
    {type => 'duration:months', level => 'm'}]],
  ['0Y0M' => 0, 0, +1,
   [{type => 'duration:syntax error', value => 'YM', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['0Y' => 0, 0, +1,
   [{type => 'duration:syntax error', value => 'Y', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['0M' => 0, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['P32M' => 0, 32, +1,
   [{type => 'duration:syntax error', value => 'PM', level => 'm'},
    {type => 'duration:months', level => 'm'}],
   undef,
   [],
   [{type => 'duration:syntax error', value => 'PM', level => 'm'},
    {type => 'duration:months', level => 'm'}]],
  ['P0Y0M' => 0, 0, +1,
   [{type => 'duration:syntax error', value => 'PYM', level => 'm'}],
   undef,
   [],
   [{type => 'duration:syntax error', value => 'PYM', level => 'm'}]],
  ['P0Y' => 0, 0, +1,
   [{type => 'duration:syntax error', value => 'PY', level => 'm'}],
   undef,
   [],
   [{type => 'duration:syntax error', value => 'PY', level => 'm'}]],
  ['P0M' => 0, 0, +1,
   [{type => 'duration:syntax error', value => 'PM', level => 'm'}],
   undef,
   [],
   [{type => 'duration:syntax error', value => 'PM', level => 'm'}]],
  ['32M10M' => 42*60, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['10s32M' => 32*60+10, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['P10s32M' => 32*60+10, 0, +1,
   [{type => 'duration:case', level => 'm', value => 's'},
    {type => 'duration:syntax error', level => 'm', value => 'PSM'}]],
  ['10d32M' => 10*24*60*60+32*60, 0, +1,
   undef,
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}]],
  ['32MPT' => undef, undef, undef],
  ['32MT' => 32*60, 0, +1,
   [{type => 'duration:syntax error', level => 'm', value => 'MT'}]],
  ['10.3d' => undef, undef, undef],
  ['PT42M31d' => 42*60+31*24*60*60, 0, +1,
   [{type => 'duration:case', level => 'm', value => 'd'},
    {type => 'duration:syntax error', level => 'm', value => 'PTMD'}]],
  ['P10h2h' => 12*60*60, 0, +1,
   [{type => 'duration:case', value => 'h', level => 'm'},
    {type => 'duration:syntax error', value => 'PHH', level => 'm'}]],
  ['31Y' => 0, 31*12, +1,
   [{type => 'duration:syntax error', value => 'Y', level => 'm'},
    {type => 'duration:months', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'},
    {type => 'duration:months', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'}],
   [{type => 'duration:html duration', level => 'm'},
    {type => 'duration:months', level => 'm'}]],
  ['P21W' => 21*7*24*60*60, 0, +1,
   [{type => 'duration:syntax error', value => 'PW', level => 'm'}], []],
  ['PT21D' => 21*24*60*60, 0, +1,
   [{type => 'duration:syntax error', value => 'PTD', level => 'm'}]],
  ['P21WT31H' => 21*7*24*60*60+31*60*60, 0, +1,
   [{type => 'duration:syntax error', value => 'PWTH', level => 'm'}]],
  ['-P21WT31H' => 21*7*24*60*60+31*60*60, 0, -1,
   [{type => 'duration:syntax error', level => 'm'}],
   undef,
   [{type => 'duration:syntax error', value => 'PWTH', level => 'm'}]],
  ['P21W31D' => 21*7*24*60*60+31*24*60*60, 0, +1,
   [{type => 'duration:syntax error', value => 'PWD', level => 'm'}]],
  ['PT12H3S' => 12*60*60+3, 0, +1,
   undef,
   [{type => 'duration:syntax error', value => 'PTHS', level => 'm'}],
   undef,
   undef,
   [{type => 'duration:syntax error', value => 'PTHS', level => 'm'}]],
  ['-PT12H3S' => 12*60*60+3, 0, -1,
   [{type => 'duration:syntax error', level => 'm'}],
   undef,
   [],
   undef,
   [{type => 'duration:syntax error', value => 'PTHS', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_duration_string ($test->[0]);
    if (defined $test->[1] and not $test->[2] and $test->[3] > 0) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->sign, $test->[3];
      is $duration && $duration->months, $test->[2];
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[4] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[4] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 5, name => ['parse_duration_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_vevent_duration_string ($test->[0]);
    if (defined $test->[1] and not $test->[2] and $test->[3] > 0) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->sign, $test->[3];
      is $duration && $duration->months, $test->[2];
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[5] || $test->[4] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[5] || $test->[4] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 5, name => ['parse_vevent_duration_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_xs_duration_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->sign, $test->[3];
      is $duration && $duration->months, $test->[2];
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[6] || $test->[4] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[6] || $test->[4] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 5, name => ['parse_xs_duration_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_xs_day_time_duration_string ($test->[0]);
    if (defined $test->[1] and not $test->[2]) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->sign, $test->[3];
      is $duration && $duration->months, $test->[2];
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[7] || $test->[6] || $test->[4] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[7] || $test->[6] || $test->[4] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 5, name => ['parse_xs_day_time_duration_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_xs_year_month_duration_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->sign, $test->[3];
      is $duration && $duration->months, $test->[2];
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[8] || $test->[6] || $test->[4] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[8] || $test->[6] || $test->[4] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 5, name => ['parse_xs_year_month_duration_string', $test->[0]];
}

for my $test (
  ['', undef, undef],
  ['z', undef, undef,
   [{type => 'datetime:lowercase designator', value => 'z', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['1000.0', undef, undef,
   [{type => 'decimal sign:period', level => 'w'},
    {type => 'duration:fraction', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['-41s', undef, undef,
   [{type => 'datetime:lowercase designator', value => 's', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['-PT31H31M', undef, undef],
  ['41s' => undef, undef,
   [{type => 'datetime:lowercase designator', value => 's', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ["10m\t30s" => undef, undef,
   [{type => 'datetime:lowercase designator', value => 's', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['420.400 s' => undef, undef,
   [{type => 'decimal sign:period', level => 'w'},
    {type => 'duration:fraction', level => 'w'},
    {type => 'datetime:lowercase designator', value => 's', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['P32M' => 0, 32],
  ['P0Y0M' => 0, 0],
  ['P0Y' => 0, 0],
  ['P0M' => 0, 0],
  ['P10s32M' => undef, undef,
   [{type => 'datetime:lowercase designator', value => 's', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['PT42M31d' => undef, undef,
   [{type => 'datetime:lowercase designator', value => 'd', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['P10h2h' => undef, undef,
   [{type => 'datetime:lowercase designator', value => 'h', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['P21W' => 21*7*24*60*60, 0],
  ['PT21D' => undef, undef],
  ['P21WT31H' => undef, undef],
  ['-P21WT31H' => undef, undef],
  ['P21W31D' => undef, undef],
  ['PT12H3S' => 12*60*60+3, 0],
  ['-PT12H3S' => undef, undef],
  ['P124Y32M323D' => 323*24*60*60, 124*12+32],
  ['P124Y32M323DT321H0M4,44S' => 323*24*60*60+321*60*60+4.44, 124*12+32,
   [{type => 'duration:fraction', level => 'w'}]],
  ['P124Y32M323D321H0M4,44S' => undef, undef,
   [{type => 'duration:fraction', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['P2012-02-00' => 2012*12*30*24*60*60+2*30*24*60*60, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P2012-02-00T10:22:44' => 2012*12*30*24*60*60+2*30*24*60*60+10*60*60+22*60+44, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P2012-02-0010:22:44' => 2012*12*30*24*60*60+2*30*24*60*60+10*60*60+22*60+44, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P2012-02-00T30:22:44' => undef, undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ['P2012-02-00T10:22:44Z' => undef, undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ['P2012-02-00T10:22:44+00:00' => undef, undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ['PT10:22:44' => 10*60*60+22*60+44, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['PT10:22' => 10*60*60+22*60, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['PT10:22.331' => 10*60*60+22.331*60, 0,
   [{type => 'decimal sign:period', level => 'w'},
    {type => 'duration:fraction', level => 'w'},
    {type => 'duration:alternative', level => 'w'}]],
  ['PT10:22,331' => 10*60*60+22.331*60, 0,
   [{type => 'duration:fraction', level => 'w'},
    {type => 'duration:alternative', level => 'w'}]],
  ['PT10.31:22,331' => undef, undef,
   [{type => 'decimal sign:period', level => 'w'},
    {type => 'duration:fraction', level => 'w'},
    {type => 'duration:syntax error', level => 'm'}]],
  ['P2012-003' => 2012*12*30*24*60*60+3*24*60*60, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P+2012-003' => 2012*12*30*24*60*60+3*24*60*60, 0,
   [{type => 'datetime:expanded year', value => '+2012', level => 'w'},
    {type => 'duration:alternative', level => 'w'}]],
  ['P+0002012-003' => 2012*12*30*24*60*60+3*24*60*60, 0,
   [{type => 'datetime:expanded year', value => '+0002012', level => 'w'},
    {type => 'duration:alternative', level => 'w'}]],
  ['P2012-W03' => undef, undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ['P23' => 2300*12*30*24*60*60, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P2012003' => 2012*12*30*24*60*60+3*24*60*60, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P20120103' => 2012*12*30*24*60*60+1*30*24*60*60+3*24*60*60, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P2012010321' => 2012*12*30*24*60*60+1*30*24*60*60+3*24*60*60+21*60*60, 0,
   [{type => 'duration:alternative', level => 'w'}]],
  ['P20121203' => undef, undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ['P20121130' => undef, undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ["P2012\x{2010}003" => 2012*12*30*24*60*60+3*24*60*60, 0,
   [{type => 'datetime:hyphen', level => 'w'},
    {type => 'duration:alternative', level => 'w'}]],
  ["P2012\x{2010}00\x{2010}13" => 2012*12*30*24*60*60+13*24*60*60, 0,
   [{type => 'datetime:hyphen', level => 'w'},
    {type => 'duration:alternative', level => 'w'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_iso8601_duration_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->sign, +1;
      is $duration && $duration->months, $test->[2];
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[3] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[3] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 5, name => ['parse_iso8601_duration_string', $test->[0]];
}

for my $test (
  ['Mo' => 'Mo'],
  ['Mo-Su' => 'Su,Mo,Tu,We,Th,Fr,Sa'],
  ['Su,Mo,Tu,We,Th,Fr,Sa' => 'Su,Mo,Tu,We,Th,Fr,Sa'],
  ['We-Tu' => 'Su,Mo,Tu,We,Th,Fr,Sa'],
  ['Mo-We,Fr-Sa' => 'Mo,Tu,We,Fr,Sa'],
  ['We,Fr 03:33-05:50' => 'We,Fr 03:33-05:50'],
  ['Sa' => 'Sa'],
  ['sa' => undef],
  ['Ho' => undef],
  ['Mo-Gr' => undef],
  ['Sa  Fr' => undef],
  ['Tu 23:44-12:00' => 'Tu 23:44-12:00'],
  ['Tu 23:44-12:00,13:00-21:00' => 'Tu 23:44-12:00,13:00-21:00'],
  ['21:33-22:00' => undef],
  ['Tu 12:00' => undef],
  ['Tue 21:33-22:00' => undef],
  ['Sa 24:01-24:30' => undef],
  ['Sa 23:60-23:61' => undef],
  ['Tu 22:00-22:00' => 'Tu 22:00-22:00'],
  ['Tu,We-Th 22:00-22:00' => 'Tu,We,Th 22:00-22:00'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $r = $parser->parse_weekly_time_range_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $r, 'Web::DateTime::WeeklyTimeRange';
      is $r && $r->to_weekly_time_range_string, $test->[1];
      eq_or_diff \@error, [];
    } else {
      is $r, undef;
      ok 1;
      eq_or_diff \@error, [{type => 'datetime:syntax error', level => 'm'}];
    }
    done $c;
  } n => 3, name => ['parse_weekly_time_range_string', $test->[0]];
}

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
