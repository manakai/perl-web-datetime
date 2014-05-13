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
      ('2010-12-13T01:02:03Z');
  my $dt = $date->to_datetime;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, 'UTC';
  done $c;
} n => 3, name => 'to_datetime';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03-00:00');
  my $dt = $date->to_datetime;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, 'floating';
  done $c;
} n => 3, name => 'to_datetime, -00:00';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03+21:44');
  my $dt = $date->to_datetime;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, '+2144';
  is $dt->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_datetime, tz';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_local_date_and_time_string
      ('2010-12-13T01:02:03');
  my $dt = $date->to_datetime;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T01:02:03';
  is $dt->time_zone->name, 'floating';
  is $dt->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_datetime, floating';

test {
  my $c = shift;
  my $date = Web::DateTime->new->parse_date_string ('2010-12-13');
  my $dt = $date->to_datetime;
  isa_ok $dt, 'DateTime';
  is $dt . '', '2010-12-13T00:00:00';
  is $dt->time_zone->name, 'floating';
  is $dt->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_datetime, date';

run_tests;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
