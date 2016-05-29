use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::More;
use Test::Differences;
use Test::X1;
use Web::DateTime;
use Web::DateTime::Parser;

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (0);
  is $date->to_unix_integer, 0;
  is $date->second_fraction_string, '';
  is $date->time_zone->offset_as_seconds, 0;
  ok $date->is_date_time;
  ok not $date->is_interval;
  ok not $date->is_time_zone;
  ok not $date->is_duration;
  done $c;
} n => 7, name => 'new_from_unix_time 0';

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (535153344);
  is $date->to_unix_integer, 535153344;
  is $date->second_fraction_string, '';
  is $date->time_zone->offset_as_seconds, 0;
  ok $date->has_component ('offset');
  ok not $date->has_component ('week');
  done $c;
} n => 5, name => 'new_from_unix_time positive';

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (-535153344);
  is $date->to_unix_integer, -535153344;
  is $date->second_fraction_string, '';
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_unix_time negative';

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (535153344.3331111004);
  is $date->to_unix_integer, 535153344;
  like $date->second_fraction_string, qr/^\.333111/;
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_unix_time positive fractional';

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (-535153344.3331111004);
  is $date->to_unix_integer, -535153345;
  like $date->second_fraction_string, qr/^\.6668/;
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_unix_time negative fractional';

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (0.00000000000000001111004);
  is $date->to_unix_integer, 0;
  like $date->second_fraction_string, qr/^\.00000/;
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_unix_time positive fractional small';

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (-0.00000000000000001111004);
  is $date->to_unix_integer, -1;
  like $date->second_fraction_string, qr/(?:^\.00000|^$)/;
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_unix_time negative fractional small';

test {
  my $c = shift;
  eval {
    Web::DateTime->new_from_object (-0.00000000000000001111004);
  };
  like $@, qr{^\QCan't create |Web::DateTime| from a ||\E};
  done $c;
} n => 1, name => 'new_from_object not object';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_global_date_and_time_string
      ('2010-12-13 01:02:03-01:00');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 13;
  is $date->utc_hour, 2;
  is $date->utc_minute, 2;
  is $date->utc_second, 3;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-13T02:02:03Z';
  is $date->to_time_zoned_global_date_and_time_string, '2010-12-13T01:02:03-01:00';
  done $c;
} n => 9, name => 'parse_global_date_and_time_string';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03Z');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 13;
  is $date->utc_hour, 1;
  is $date->utc_minute, 2;
  is $date->utc_second, 3;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-13T01:02:03Z';
  is $date->to_time_zoned_global_date_and_time_string, '2010-12-13T01:02:03Z';
  done $c;
} n => 9, name => 'parse_global_date_and_time_string';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_month_string
      ('2010-12');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 1;
  is $date->utc_hour, 0;
  is $date->utc_minute, 0;
  is $date->utc_second, 0;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-01T00:00:00Z';
  is $date->to_month_string, '2010-12';
  done $c;
} n => 9, name => 'parse_month_string';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_date_string
      ('2000-02-29');
  is $date->utc_year, 2000;
  is $date->utc_month, 2;
  is $date->utc_day, 29;
  is $date->utc_hour, 0;
  is $date->utc_minute, 0;
  is $date->utc_second, 0;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2000-02-29T00:00:00Z';
  is $date->to_date_string, '2000-02-29';
  done $c;
} n => 9, name => 'parse_date_string';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_local_date_and_time_string
      ('2000-02-29 21:33:11.00');
  is $date->utc_year, 2000;
  is $date->utc_month, 2;
  is $date->utc_day, 29;
  is $date->utc_hour, 21;
  is $date->utc_minute, 33;
  is $date->utc_second, 11;
  is $date->second_fraction_string, '';
  is $date->to_local_date_and_time_string, '2000-02-29T21:33:11';
  is $date->to_time_zoned_global_date_and_time_string, '2000-02-29T21:33:11Z';
  is $date->time_zone, undef;
  done $c;
} n => 10, name => 'parse_local_date_and_time_string';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_week_string ('2010-W01');
  is $date->to_week_string, '2010-W01';
  is $date->utc_year, 2010;
  is $date->utc_month, 1;
  is $date->utc_day, 4;
  is $date->utc_week_year, 2010;
  is $date->utc_week, 1;
  is $date->to_week_string, '2010-W01';

  $date = Web::DateTime::Parser->new->parse_week_string ('2010-W51');
  is $date->to_week_string, '2010-W51';
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 20;

  $date = Web::DateTime::Parser->new->parse_week_string ('2010-W52');
  is $date->to_week_string, '2010-W52';
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 27;

  $date = Web::DateTime::Parser->new->parse_week_string ('2010-W00');
  is $date, undef;

  $date = Web::DateTime::Parser->new->parse_week_string ('2010-W53');
  is $date, undef;
  done $c;
} n => 17, name => 'parse_week_string';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_date_string_with_optional_time
      ('2010-12-13 01:02:03-01:00');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 13;
  is $date->utc_hour, 2;
  is $date->utc_minute, 2;
  is $date->utc_second, 3;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-13T02:02:03Z';
  is $date->to_date_string_with_optional_time, '2010-12-13T01:02:03-01:00';
  done $c;
} n => 9, name => 'parse_date_string_with_optional_time';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_date_string_with_optional_time
      ('2010-12-13');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 13;
  is $date->utc_hour, 0;
  is $date->utc_minute, 0;
  is $date->utc_second, 0;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-13T00:00:00Z';
  is $date->to_date_string_with_optional_time, '2010-12-13';
  is $date->time_zone, undef;
  done $c;
} n => 10, name => 'parse_date_string_with_optional_time';

for my $test (
  ['00:00:00' => '00:00'],
  ['00:00:00.0000' => '00:00'],
  ['00:00:00.000000000001' => '00:00:00.000000000001'],
  ['00:00:01' => '00:00:01'],
  ['00:00:30.0000' => '00:00:30'],
  ['00:00:03.000000000001' => '00:00:03.000000000001'],
  ['00:03' => '00:03'],
  ['00:03:00.44440014440000' => '00:03:00.4444001444'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_time_string ($test->[0]);
    is $dt->to_shortest_time_string, $test->[1];
    done $c;
  } n => 1, name => ['to_shortest_time_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_local_date_and_time_string
        ('2013-01-04T' . $test->[0]);
    is $dt->to_normalized_local_date_and_time_string,
        '2013-01-04T' . $test->[1];
    done $c;
  } n => 1, name => ['to_normalized_local_date_and_time_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_global_date_and_time_string
        ('2013-01-04T' . $test->[0] . 'Z');
    is $dt->to_normalized_forced_utc_global_date_and_time_string,
        '2013-01-04T' . $test->[1] . 'Z';
    done $c;
  } n => 1, name => ['to_normalized_forced_utc_global_date_and_time_string', $test->[0]];
}

for my $test (
  ['00:00:00' => '17:30'],
  ['00:00:00.0000' => '17:30'],
  ['00:00:00.000000000001' => '17:30:00.000000000001'],
  ['00:00:01' => '17:30:01'],
  ['00:00:30.0000' => '17:30:30'],
  ['00:00:03.000000000001' => '17:30:03.000000000001'],
  ['00:03' => '17:33'],
  ['00:03:00.44440014440000' => '17:33:00.4444001444'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_global_date_and_time_string
        ('2013-01-04T' . $test->[0] . '+06:30');
    is $dt->to_normalized_forced_utc_global_date_and_time_string,
        '2013-01-03T' . $test->[1] . 'Z';
    done $c;
  } n => 1, name => ['to_normalized_forced_utc_global_date_and_time_string', $test->[0]];
}

for my $test (
  ['1001'],
  ['1002'],
  ['2010'],
  ['03002', '3002'],
  ['10002'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_year_string ($test->[0]);
    is $dt->to_year_string, $test->[1] || $test->[0];
    done $c;
  } n => 1, name => ['to_year_string', $test->[0]];
}

for my $test (
  ['12-21' => '--12-21'],
  ['01-01' => '--01-01'],
  ['--10-30'],
  ['--02-29'],
  ['--11-01'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_yearless_date_string ($test->[0]);
    is $dt->to_yearless_date_string, $test->[1] || $test->[0];
    done $c;
  } n => 1, name => ['to_yearless_date_string', $test->[0]];
}

for my $test (
  ['2013-01-03' => 'DateTime', '2013-01-03T00:00:00Z'],
  ['2013-01-03T04:12:33Z' => 'DateTime', '2013-01-03T04:12:33Z'],
  ['2013-01-03T04:12:33+12:33' => 'DateTime', '2013-01-02T15:39:33Z'],
  ['2013-01-03T04:12:33Z/2013-01-03T04:12:33-01:00' => 'Interval', '2013-01-03T04:12:33Z/PT3600S'],
  ['2013-01-03T04:12:33Z/2013-01-03T03:12:33-01:00' => 'Interval', '2013-01-03T04:12:33Z/PT0S'],
  ['2013-01-03T04:12:33Z/PT31M' => 'Interval', '2013-01-03T04:12:33Z/PT1860S'],
  ['2013-01-03T04:12:33Z/PT31M1.32S' => 'Interval', '2013-01-03T04:12:33Z/PT1861S',
   [{type => 'datetime:fractional second', level => 'm'}]],
  ['2013-01-03T04:12:33Z/PT1S31M' => 'Interval', '2013-01-03T04:12:33Z/PT1861S',
   [{type => 'duration:syntax error', value => 'PTSM', level => 'm'}]],
  ['2013-01-03T04:12:33Z/' => 'Error', undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ['2013-01-03T04:12:33Z/PT31M/' => 'Error', undef,
   [{type => 'duration:syntax error', level => 'm'}]],
  ['2013-01-03T04:12:33/PT31M' => 'Error', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2013-01-03/PT31M' => 'Error', undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2013-01-03T04:12:33Z/50S' => 'Interval', '2013-01-03T04:12:33Z/PT50S',
   [{type => 'duration:html duration', level => 'm'}]],
  ['2013-01-03T04:12:33Z/2013-01-03T04:12:33' => 'Error', '',
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2013-01-03T04:12:33Z/2013-01-03T04:12:32Z' => 'Error', '',
   [{type => 'interval:not 1<=2', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_date_string_with_optional_time_and_duration
        ($test->[0]);
    if ($test->[1] eq 'Interval') {
      isa_ok $dt, 'Web::DateTime::Interval';
      is $dt->to_start_and_duration_string, $test->[2];
    } elsif ($test->[1] eq 'DateTime') {
      isa_ok $dt, 'Web::DateTime';
      is $dt->to_global_date_and_time_string, $test->[2];
    } else {
      is $dt, undef;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 3, name => ['parse_date_string_with_optional_time_and_duration', $test->[0]];
}

for my $test (
  ['2013-01-01T00:12:22Z' => '2013-01-01T00:12:22Z', 'Z'],
  ['2013-01-01T00:12:22+12:00' => '2012-12-31T12:12:22Z', '+12:00'],
  ['2013-01-01T00:12:22+14:00' => '2012-12-31T10:12:22Z', '+14:00'],
  ['2013-01-01T00:12:22-14:00' => '2013-01-01T14:12:22Z', '-14:00'],
  ['2013-01-01T00:12:22+14:01' => undef, undef,
   [{type => 'datetime:bad timezone hour', value => '+14', level => 'm'}]],
  ['2013-01-01T00:12:22-14:01' => undef, undef,
   [{type => 'datetime:bad timezone hour', value => '-14', level => 'm'}]],
  ['2014-01-01T00:12:33' => '2014-01-01T00:12:33Z', undef],
  ['2014-01-01T00:12:33.000' => '2014-01-01T00:12:33Z', undef],
  ['2014-01-01T00:12:33.123' => '2014-01-01T00:12:33.123Z', undef],
  ['2014-01-01T00:12Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2014-01-01 00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2013-01-01T24:00:00Z' => '2013-01-02T00:00:00Z', 'Z'],
  ['2014-01-01T24:00:00.1Z' => undef, undef,
   [{type => 'datetime:bad hour', value => 24, level => 'm'}]],
  ['2014-01-01T24:00:01Z' => undef, undef,
   [{type => 'datetime:bad hour', value => 24, level => 'm'}]],
  ['01113-01-01T00:12:22+12:00' => '1112-12-31T12:12:22Z', '+12:00',
   [{type => 'datetime:year leading 0', value => '01113', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_date_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_date_time_string', $test->[0]];
}

for my $test (
  ['2013-01-01T00:12:22Z' => '2013-01-01T00:12:22Z', 'Z'],
  ['2013-01-01T00:12:22+12:00' => '2012-12-31T12:12:22Z', '+12:00'],
  ['2013-01-01T00:12:22+14:00' => '2012-12-31T10:12:22Z', '+14:00'],
  ['2013-01-01T00:12:22-14:00' => '2013-01-01T14:12:22Z', '-14:00'],
  ['2013-01-01T00:12:22+14:01' => undef, undef,
   [{type => 'datetime:bad timezone hour', value => '+14', level => 'm'}]],
  ['2013-01-01T00:12:22-14:01' => undef, undef,
   [{type => 'datetime:bad timezone hour', value => '-14', level => 'm'}]],
  ['2014-01-01T00:12Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2014-01-01T00:12:33' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2014-01-01 00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2013-01-01T24:00:00Z' => '2013-01-02T00:00:00Z', 'Z'],
  ['2014-01-01T24:00:00.1Z' => undef, undef,
   [{type => 'datetime:bad hour', value => 24, level => 'm'}]],
  ['2014-01-01T24:00:01Z' => undef, undef,
   [{type => 'datetime:bad hour', value => 24, level => 'm'}]],
  ['01113-01-01T00:12:22+12:00' => '1112-12-31T12:12:22Z', '+12:00',
   [{type => 'datetime:year leading 0', value => '01113', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_date_time_stamp_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      is $dt && $dt->time_zone->to_offset_string, $test->[2];
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_date_time_stamp_string', $test->[0]];
}

for my $test (
  ['' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['12:44:11' => '1970-01-01T12:44:11Z', undef],
  ['12:44:11Z' => '1970-01-01T12:44:11Z', 'Z'],
  ['12:44:11-00:00' => '1970-01-01T12:44:11Z', 'Z'],
  ['24:00:00' => '1970-01-02T00:00:00Z', undef],
  ['12:44:11.134' => '1970-01-01T12:44:11.134Z', undef],
  ['12:44:11+09:00' => '1970-01-01T03:44:11Z', '+09:00'],
  ['12:44:11+14:00' => '1969-12-31T22:44:11Z', '+14:00'],
  ['12:44:11+14:01' => undef, undef,
   [{type => 'datetime:bad timezone hour', value => '+14', level => 'm'}]],
  ['12:44:11-14:00' => '1970-01-02T02:44:11Z', '-14:00'],
  ['12:44:11-14:01' => undef, undef,
   [{type => 'datetime:bad timezone hour', value => '-14', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_time_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_time_string', $test->[0]];
}

for my $test (
  ['' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-01-05' => '2012-01-05T00:00:00Z', undef],
  ['2012-01-05Z' => '2012-01-05T00:00:00Z', 'Z'],
  ['2012-01-05-12:33' => '2012-01-05T12:33:00Z', '-12:33'],
  ['2012-04-05T00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['02040-04-30' => '2040-04-30T00:00:00Z', undef,
   [{type => 'datetime:year leading 0', value => '02040', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_date_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_date_string', $test->[0]];
}

for my $test (
  ['' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012-01' => '2012-01-01T00:00:00Z', undef],
  ['2012-01Z' => '2012-01-01T00:00:00Z', 'Z'],
  ['2012-01-12:33' => '2012-01-01T12:33:00Z', '-12:33'],
  ['2012-04T00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['02040-04' => '2040-04-01T00:00:00Z', undef,
   [{type => 'datetime:year leading 0', value => '02040', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_g_year_month_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_g_year_month_string', $test->[0]];
}

for my $test (
  ['' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['2012' => '2012-01-01T00:00:00Z', undef],
  ['2012Z' => '2012-01-01T00:00:00Z', 'Z'],
  ['2012-12:33' => '2012-01-01T12:33:00Z', '-12:33'],
  ['2012T00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['02040' => '2040-01-01T00:00:00Z', undef,
   [{type => 'datetime:year leading 0', value => '02040', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_g_year_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_g_year_string', $test->[0]];
}

for my $test (
  ['' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['--02-12' => '2000-02-12T00:00:00Z', undef],
  ['--02-29Z' => '2000-02-29T00:00:00Z', 'Z'],
  ['--02-29-12:33' => '2000-02-29T12:33:00Z', '-12:33'],
  ['--02-29T00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['--02-30' => undef, undef,
   [{type => 'datetime:bad day', value => '30', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_g_month_day_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_g_month_day_string', $test->[0]];
}

for my $test (
  ['' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['--02' => '2000-02-01T00:00:00Z', undef],
  ['--02Z' => '2000-02-01T00:00:00Z', 'Z'],
  ['--02-12:33' => '2000-02-01T12:33:00Z', '-12:33'],
  ['--02T00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['--13' => undef, undef,
   [{type => 'datetime:bad month', value => '13', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_g_month_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_g_month_string', $test->[0]];
}

for my $test (
  ['' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['---31' => '2000-01-31T00:00:00Z', undef],
  ['---29Z' => '2000-01-29T00:00:00Z', 'Z'],
  ['---29-12:33' => '2000-01-29T12:33:00Z', '-12:33'],
  ['---29T00:12:33Z' => undef, undef,
   [{type => 'datetime:syntax error', level => 'm'}]],
  ['---32' => undef, undef,
   [{type => 'datetime:bad day', value => '32', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $dt = $parser->parse_xs_g_day_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $dt, 'Web::DateTime';
      is $dt && $dt->to_global_date_and_time_string, $test->[1];
      if (defined $test->[2]) {
        is $dt && $dt->time_zone->to_offset_string, $test->[2];
      } else {
        is $dt->time_zone, undef;
      }
    } else {
      is $dt, undef;
      ok 1;
      ok 1;
    }
    eq_or_diff \@error, $test->[3] || [];
    done $c;
  } n => 4, name => ['parse_xs_g_day_string', $test->[0]];
}

for my $test (
  ['2012-05-01T00:12:01.444Z' => 'Tue, 01 May 2012 00:12:01 GMT'],
  ['2212-05-01T00:12:01.444+04:10' => 'Thu, 30 Apr 2212 20:02:01 GMT'],
  ['1970-01-01T00:00:00Z' => 'Thu, 01 Jan 1970 00:00:00 GMT'],
  ['2012-02-29T00:12:31Z' => 'Wed, 29 Feb 2012 00:12:31 GMT'],
  ['2012-02-29T00:12:31-00:00' => 'Wed, 29 Feb 2012 00:12:31 GMT'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_rfc3339_date_time_string ($test->[0]);
    is $dt->to_http_date_string, $test->[1];
    done $c;
  } n => 1, name => ['to_http_date_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_rfc3339_date_time_string ($test->[0]);
    my $expected = $test->[1];
    $expected =~ s/ GMT$/ +0000/;
    is $dt->to_rss2_date_time_string, $expected;
    done $c;
  } n => 1, name => ['to_rss2_date_time_string', $test->[0]];
}

for my $test (
  ['2012-05-01T00:12:01.444Z' => '20120501001201Z'],
  ['2212-05-01T00:12:01.444+04:10' => '22120430200201Z'],
  ['1970-01-01T00:00:00Z' => '19700101000000Z'],
  ['2012-02-29T00:12:31Z' => '20120229001231Z'],
  ['2012-02-29T00:12:31-00:00' => '20120229001231Z'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_rfc3339_date_time_string ($test->[0]);
    is $dt->to_generalized_time_string, $test->[1];
    done $c;
  } n => 1, name => ['to_generalized_time_string', $test->[0]];
}

for my $test (
  ['2012-05-01T00:12:01.444Z' => '05/01/2012 00:12:01'],
  ['2212-05-01T00:12:01.444+04:10' => '05/01/2212 00:12:01'],
  ['1970-01-01T00:00:00Z' => '01/01/1970 00:00:00'],
  ['2012-02-29T00:12:31Z' => '02/29/2012 00:12:31'],
  ['2012-02-29T00:12:31-00:00' => '02/29/2012 00:12:31'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my $dt = $parser->parse_rfc3339_date_time_string ($test->[0]);
    is $dt->to_document_last_modified_string, $test->[1];
    done $c;
  } n => 1, name => ['to_document_last_modified_string', $test->[0]];
}

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_unix_time (414345555);
  is $dt->to_document_last_modified_string, '02/17/1983 15:59:15';
  $dt->set_time_zone
      (Web::DateTime::Parser->parse_time_zone_offset_string ('+09:00'));
  is $dt->to_document_last_modified_string, '02/18/1983 00:59:15';
  $dt->set_time_zone
      (Web::DateTime::Parser->parse_time_zone_offset_string ('-04:30'));
  is $dt->to_document_last_modified_string, '02/17/1983 11:29:15';
  $dt->set_time_zone (undef);
  is $dt->to_document_last_modified_string, '02/17/1983 15:59:15';
  done $c;
} n => 4, name => ['set_time_zone'];

test {
  my $c = shift;

  my $dt0 = Web::DateTime->new_from_unix_time (135555555);
  is $dt0->second, 15;
  is $dt0->to_unix_integer, 135555555;
  is $dt0->to_unix_number, 135555555;
  is $dt0->to_html_number, 135555555000;

  my $dt = Web::DateTime->new_from_unix_time (135555555.3113);
  is $dt->second, 15;
  is $dt->to_unix_integer, $dt0->to_unix_integer;
  is $dt->to_unix_number, 135555555.3113;
  is $dt->to_html_number, 135555555311.3;
  is $dt->to_jd, 2442156.43003833;
  is $dt->to_mjd, 42155.930038325;
  is $dt->to_rd, 720731.930038325;

  done $c;
} n => 11, name => 'to_unix number';

test {
  my $c = shift;

  my $dt0 = Web::DateTime->new_from_unix_time (0);
  is $dt0->second, 0;
  is $dt0->to_unix_integer, 0;
  is $dt0->to_unix_number, 0;
  is $dt0->to_html_number, 0;
  is $dt0->to_jd, 2440587.5;
  is $dt0->to_mjd, 40587;
  is $dt0->to_rd, 719163;

  done $c;
} n => 7, name => 'to_unix number';

test {
  my $c = shift;

  my $dt0 = Web::DateTime->new_from_unix_time (-135555556);
  is $dt0->second, 44;
  is $dt0->to_unix_integer, -135555556;
  is $dt0->to_unix_number, -135555556;
  is $dt0->to_html_number, -135555556000;

  my $dt = Web::DateTime->new_from_unix_time (-135555555.3113);
  is $dt->second, 44;
  is $dt->to_unix_integer, $dt0->to_unix_integer;
  is $dt->to_unix_number, -135555555.3113;
  is $dt->to_html_number, -135555555311.3;
  is $dt->to_jd, 2439018.56996167;
  is $dt->to_mjd, 39018.069961675;
  is $dt->to_rd, 717594.069961675;

  done $c;
} n => 11, name => 'to_unix number negative fractional';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (2012, 6, 7, 1, 3, 6.4);
  is $dt->year, 2012;
  is $dt->month, 6;
  is $dt->day, 7;
  is $dt->hour, 1;
  is $dt->minute, 3;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (2012, 0, 1, 11, 10, 6.4);
  is $dt->year, 2011;
  is $dt->month, 12;
  is $dt->day, 1;
  is $dt->hour, 11;
  is $dt->minute, 10;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (2012, 0, 0, 11, 10, 6.4);
  is $dt->year, 2011;
  is $dt->month, 11;
  is $dt->day, 30;
  is $dt->hour, 11;
  is $dt->minute, 10;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (2012, 28, 37, 41, 103, 6.4);
  is $dt->year, 2014;
  is $dt->month, 5;
  is $dt->day, 8;
  is $dt->hour, 18;
  is $dt->minute, 43;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (2012, -3, 37, 41, 103, 6.4);
  is $dt->year, 2011;
  is $dt->month, 10;
  is $dt->day, 8;
  is $dt->hour, 18;
  is $dt->minute, 43;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (32, 6, 7, 1, 3, 6.4);
  is $dt->year, 32;
  is $dt->month, 6;
  is $dt->day, 7;
  is $dt->hour, 1;
  is $dt->minute, 3;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (0, 6, 7, 1, 3, 6.4);
  is $dt->year, 0;
  is $dt->month, 6;
  is $dt->day, 7;
  is $dt->hour, 1;
  is $dt->minute, 3;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (-2012, 6, 7, 1, 3, 6.4);
  is $dt->year, -2012;
  is $dt->month, 6;
  is $dt->day, 7;
  is $dt->hour, 1;
  is $dt->minute, 3;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components
      (-153, 6, 7, 1, 3, 6.4);
  is $dt->year, -153;
  is $dt->month, 6;
  is $dt->day, 7;
  is $dt->hour, 1;
  is $dt->minute, 3;
  is $dt->second, 6;
  like $dt->second_fraction_string, qr{^\.4};
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

test {
  my $c = shift;
  my $dt = Web::DateTime->new_from_components;
  is $dt->year, 1970;
  is $dt->month, 1;
  is $dt->day, 1;
  is $dt->hour, 0;
  is $dt->minute, 0;
  is $dt->second, 0;
  is $dt->second_fraction_string, '';
  is $dt->time_zone, undef;
  done $c;
} n => 8, name => 'new_from_components';

for my $test (
  [2299161, '1582-10-15'],
  [2345678, '1710-02-23'],
  [2400000.5, '1858-11-17'],
  [2451545, '2000-01-01'],
  [4000000, '6239-07-12'],
) {
  test {
    my $c = shift;
    my $dt = Web::DateTime->new_from_jd ($test->[0]);
    is $dt->to_ymd_string, $test->[1];
    done $c;
  } n => 1, name => ['new_from_jd', $test->[0]];
}

for my $test (
  [-2399963, '-4712-01-01'],
  [-605833,  '0200-03-01'],
  [-100840,  '1582-10-15'],
  [51544,    '2000-01-01'],
) {
  test {
    my $c = shift;
    my $dt = Web::DateTime->new_from_mjd ($test->[0]);
    is $dt->to_ymd_string, $test->[1];
    done $c;
  } n => 1, name => ['new_from_mjd', $test->[0]];
}

for my $test (
  [[-402000, 1, 2] => '-402000', '-402000-01-02'],
  [[-2000, 1, 2] => '-2000', '-2000-01-02'],
  [[0, 1, 2] => '0000', '0000-01-02'],
  [[900, 1, 2] => '0900', '0900-01-02'],
  [[2000, 1, 2] => '2000', '2000-01-02'],
  [[2000, 12, 31] => '2000', '2000-12-31'],
  [[12000, 12, 31] => '12000', '12000-12-31'],
) {
  test {
    my $c = shift;
    my $dt = Web::DateTime->new_from_components (@{$test->[0]});
    is $dt->to_manakai_year_string, $test->[1];
    is $dt->to_ymd_string, $test->[2];
    done $c;
  } n => 2, name => ['to_manakai_year_string / to_ymd_string', $test->[2]];
}

for my $test (
  [0 => '-4712-01-01', -4712, 1, 1],
  [1234567 => '-1332-01-23', -1332, 1, 23],
  [2299160 => '1582-10-04', 1582, 10, 4],
) {
  test {
    my $c = shift;
    my $dt = Web::DateTime->new_from_jd ($test->[0]);
    is $dt->to_julian_ymd_string, $test->[1];
    is $dt->julian_year, $test->[2];
    is $dt->julian_month, $test->[3];
    is $dt->julian_day, $test->[4];
    done $c;
  } n => 4, name => ['julian', $test->[1]];
}

run_tests;

=head1 LICENSE

Copyright 2008-2016 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
