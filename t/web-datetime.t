use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->parent->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->parent->subdir ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::More;
use Test::X1;
use Web::DateTime;

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
  done $c;
} n => 8, name => 'parse_global_date_and_time_string';

#test {
#  my $c = shift;
#  my $date = Web::DateTime->new->parse_global_date_and_time_string
#      ('2010-12-13T01:02:03Z');
#  my $dt = $date->to_datetime;
#  isa_ok $dt, 'DateTime';
#  is $dt . '', '2010-12-13T01:02:03';
#  is $dt->time_zone->name, 'UTC';
#  done $c;
#} n => 3, name => 'to_datetime';

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
  is $date, undef;

  $date = Web::DateTime->new->parse_week_string ('2010-W53');
  is $date, undef;
  done $c;
} n => 14, name => 'parse_week_string';

run_tests;
