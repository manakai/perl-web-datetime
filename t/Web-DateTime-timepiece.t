use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::More;
use Test::X1;
use Web::DateTime;
use Web::DateTime::Parser;
use Time::Piece;

local $ENV{TZ} = 'GMT+4';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03Z');
  my $tp = $date->to_time_piece_gm;
  isa_ok $tp, 'Time::Piece';
  is $tp->ymd, '2010-12-13';
  is $tp->hms, '01:02:03';
  is $tp->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_time_piece_gm';

test {
  my $c = shift;
  my $date = Web::DateTime::Parser->new->parse_global_date_and_time_string
      ('2010-12-13T01:02:03Z');
  my $tp = $date->to_time_piece_local;
  isa_ok $tp, 'Time::Piece';
  is $tp->ymd, '2010-12-12';
  is $tp->hms, '21:02:03';
  is $tp->epoch, $date->to_unix_integer;
  done $c;
} n => 4, name => 'to_time_piece_local';

test {
  my $c = shift;
  my $tp = Time::Piece->gmtime (521534555);
  my $date = Web::DateTime->new_from_object ($tp);
  isa_ok $date, 'Web::DateTime';
  is $date->to_unix_integer, $tp->epoch;
  is $date->time_zone->offset_as_seconds, $tp->tzoffset->seconds;
  is $date->time_zone->offset_as_seconds, 0;
  done $c;
} n => 4, name => 'new_from_object Time::Piece::gmtime';

test {
  my $c = shift;
  my $tp = Time::Piece->localtime (521534555);
  my $date = Web::DateTime->new_from_object ($tp);
  isa_ok $date, 'Web::DateTime';
  is $date->to_unix_integer, $tp->epoch;
  is $date->time_zone->offset_as_seconds, $tp->tzoffset->seconds;
  is $date->time_zone->offset_as_seconds, -4 * 3600;
  ok $date->has_component ('year');
  ok $date->has_component ('day');
  ok $date->has_component ('offset');
  done $c;
} n => 7, name => 'new_from_object Time::Piece::localtime';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
