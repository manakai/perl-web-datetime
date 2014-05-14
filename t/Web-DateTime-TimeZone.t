use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Web::DateTime::TimeZone;

test {
  my $c = shift;
  my $tz = Web::DateTime::TimeZone->new_utc;
  isa_ok $tz, 'Web::DateTime::TimeZone';
  is $tz->offset_as_seconds, 0;
  is $tz->offset_sign, +1;
  is $tz->offset_hour, 0;
  is $tz->offset_minute, 0;
  is $tz->to_offset_string, 'Z';
  ok not $tz->is_datetime;
  ok not $tz->is_period;
  ok $tz->is_time_zone;
  ok not $tz->is_duration;
  done $c;
} n => 10, name => 'new_utc';

test {
  my $c = shift;
  my $tz = Web::DateTime::TimeZone->new_from_offset (0);
  isa_ok $tz, 'Web::DateTime::TimeZone';
  is $tz->offset_as_seconds, 0;
  is $tz->offset_sign, +1;
  is $tz->offset_hour, 0;
  is $tz->offset_minute, 0;
  is $tz->to_offset_string, 'Z';
  done $c;
} n => 6, name => 'new_from_offset 0';

test {
  my $c = shift;
  my $tz = Web::DateTime::TimeZone->new_from_offset (-1 * 10 * 3600 + 5 * 60);
  isa_ok $tz, 'Web::DateTime::TimeZone';
  is $tz->offset_as_seconds, -35700;
  is $tz->offset_sign, -1;
  is $tz->offset_hour, 9;
  is $tz->offset_minute, 55;
  is $tz->to_offset_string, '-09:55';
  done $c;
} n => 6, name => 'new_from_offset -';

test {
  my $c = shift;
  my $tz = Web::DateTime::TimeZone->new_from_offset (13 * 3600 + 5 * 60);
  isa_ok $tz, 'Web::DateTime::TimeZone';
  is $tz->offset_as_seconds, 47100;
  is $tz->offset_sign, +1;
  is $tz->offset_hour, 13;
  is $tz->offset_minute, 5;
  is $tz->to_offset_string, '+13:05';
  done $c;
} n => 6, name => 'new_from_offset +';

test {
  my $c = shift;
  my $tz = Web::DateTime::TimeZone->new_from_offset (13 * 3600 + 5 * 60);
  isa_ok $tz, 'Web::DateTime::TimeZone';
  is $tz->offset_as_seconds, 47100;
  is $tz->offset_sign, +1;
  is $tz->offset_hour, 13;
  is $tz->offset_minute, 5;
  is $tz->to_offset_string, '+13:05';
  done $c;
} n => 6, name => 'new_from_offset +';

run_tests;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
