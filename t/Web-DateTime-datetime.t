use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::More;
use Test::X1;
use Web::DateTime;
use Web::DateTime::Parser;
use DateTime;

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03Z');
  my $dt = $date->to_date_time;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, 'UTC';
  done $c;
} n => 3, name => 'to_date_time';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03-00:00');
  my $dt = $date->to_date_time;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, 'UTC';
  done $c;
} n => 3, name => 'to_date_time, -00:00';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03+21:44');
  my $dt = $date->to_date_time;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, '+2144';
  is $dt->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_date_time, tz';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_local_date_and_time_string
      ('2010-12-13T01:02:03');
  my $dt = $date->to_date_time;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, 'floating';
  is $dt->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_date_time, floating';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_date_string ('2010-12-13');
  my $dt = $date->to_date_time;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T00:00:00';
  is $dt->time_zone->name, 'floating';
  is $dt->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_date_time, date';

test {
  my $c = shift;
  my $dt = DateTime->from_epoch (epoch => 521534555, time_zone => 'UTC');
  my $date = Web::DateTime->new_from_object ($dt);
  isa_ok $date, 'Web::DateTime';
  is $date->to_unix_integer, $dt->epoch;
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 3, name => 'new_from_object DateTime UTC';

test {
  my $c = shift;
  my $dt = DateTime->from_epoch (epoch => 521534555, time_zone => '+04:00');
  my $date = Web::DateTime->new_from_object ($dt);
  isa_ok $date, 'Web::DateTime';
  is $date->to_unix_integer, $dt->epoch;
  is $date->time_zone->offset_as_seconds, +4*3600;
  ok $date->has_component ('year');
  ok $date->has_component ('day');
  ok $date->has_component ('offset');
  done $c;
} n => 6, name => 'new_from_object DateTime non UTC';

test {
  my $c = shift;
  my $dt = DateTime->from_epoch (epoch => 521534555, time_zone => 'floating');
  my $date = Web::DateTime->new_from_object ($dt);
  isa_ok $date, 'Web::DateTime';
  is $date->to_unix_integer, $dt->epoch;
  is $date->second_fraction_string, '';
  ok $date->has_component ('year');
  ok $date->has_component ('day');
  ok not $date->has_component ('offset');
  is $date->time_zone, undef;
  done $c;
} n => 7, name => 'new_from_object DateTime floating';

test {
  my $c = shift;
  my $dt = DateTime->from_epoch (epoch => 521534555);
  $dt->set_nanosecond (4442222);
  my $date = Web::DateTime->new_from_object ($dt);
  isa_ok $date, 'Web::DateTime';
  is $date->to_unix_integer, $dt->epoch;
  is $date->time_zone->offset_as_seconds, 0;
  like $date->second_fraction_string, qr/^\.00444/;
  done $c;
} n => 4, name => 'new_from_object DateTime fractional';

test {
  my $c = shift;
  my $dt = DateTime->new (year => 1972, month => 12, day => 31,
                          hour => 23, minute => 59, second => 60,
                          time_zone => 'UTC');
  my $date = Web::DateTime->new_from_object ($dt);
  isa_ok $date, 'Web::DateTime';
  is $date->to_unix_integer, $dt->epoch;
  is $date->time_zone->offset_as_seconds, 0;
  is $date->year, 1973;
  is $date->month, 1;
  is $date->day, 1;
  is $date->hour, 0;
  is $date->minute, 0;
  is $date->second, 0;
  done $c;
} n => 9, name => 'new_from_object DateTime leap second';

run_tests;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
