use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::More;
use Test::X1;
use Web::DateTime;
use Web::DateTime::Parser;

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (0);
  is $date->to_unix_integer, 0;
  is $date->second_fraction_string, '';
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_unix_time 0';

test {
  my $c = shift;
  my $date = Web::DateTime->new_from_unix_time (535153344);
  is $date->to_unix_integer, 535153344;
  is $date->second_fraction_string, '';
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_unix_time positive';

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
} n => 14, name => 'parse_week_string';

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

run_tests;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
