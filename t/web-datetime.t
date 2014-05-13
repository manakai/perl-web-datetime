use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::More;
use Test::X1;
use Web::DateTime;

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_global_date_and_time_string
      ('2010-12-13 01:02:03-01:00');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 13;
  is $date->utc_hour, 2;
  is $date->utc_minute, 2;
  is $date->utc_second, 3;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-13T02:02:03Z';
  is $date->to_timezoned_global_date_and_time_string, '2010-12-13T01:02:03-01:00';
  done $c;
} n => 9, name => 'parse_global_date_and_time_string';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03Z');
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 13;
  is $date->utc_hour, 1;
  is $date->utc_minute, 2;
  is $date->utc_second, 3;
  is $date->second_fraction_string, '';
  is $date->to_global_date_and_time_string, '2010-12-13T01:02:03Z';
  is $date->to_timezoned_global_date_and_time_string, '2010-12-13T01:02:03Z';
  done $c;
} n => 9, name => 'parse_global_date_and_time_string';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_month_string
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
  my $date = Web::DateTime->new->parse_date_string
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
  my $date = Web::DateTime->new->parse_local_date_and_time_string
      ('2000-02-29 21:33:11.00');
  is $date->utc_year, 2000;
  is $date->utc_month, 2;
  is $date->utc_day, 29;
  is $date->utc_hour, 21;
  is $date->utc_minute, 33;
  is $date->utc_second, 11;
  is $date->second_fraction_string, '';
  is $date->to_local_date_and_time_string, '2000-02-29T21:33:11';
  is $date->to_timezoned_global_date_and_time_string, '2000-02-29T21:33:11Z';
  is $date->timezone_string, undef;
  done $c;
} n => 10, name => 'parse_local_date_and_time_string';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_week_string ('2010-W01');
  is $date->to_week_string, '2010-W01';
  is $date->utc_year, 2010;
  is $date->utc_month, 1;
  is $date->utc_day, 4;

  $date = Web::DateTime->new->parse_week_string ('2010-W51');
  is $date->to_week_string, '2010-W51';
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 20;

  $date = Web::DateTime->new->parse_week_string ('2010-W52');
  is $date->to_week_string, '2010-W52';
  is $date->utc_year, 2010;
  is $date->utc_month, 12;
  is $date->utc_day, 27;

  $date = Web::DateTime->new->parse_week_string ('2010-W00');
  ok not $date->has_value;

  $date = Web::DateTime->new->parse_week_string ('2010-W53');
  ok not $date->has_value;
  done $c;
} n => 14, name => 'parse_week_string';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_date_string_with_optional_time
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
  my $date = Web::DateTime->new->parse_date_string_with_optional_time
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
  is $date->timezone_string, undef;
  done $c;
} n => 10, name => 'parse_date_string_with_optional_time';

run_tests;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
