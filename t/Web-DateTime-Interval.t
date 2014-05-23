use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Web::DateTime::Interval;
use Web::DateTime::Parser;

test {
  my $c = shift;
  my $dt1 = Web::DateTime::Parser->parse_global_date_and_time_string
      ('2000-01-05T00:12:33Z');
  my $dt2 = Web::DateTime::Parser->parse_global_date_and_time_string
      ('2200-11-05T09:02:33.4+01:00');
  my $interval = Web::DateTime::Interval->new_from_start_and_end ($dt1, $dt2);
  is $interval->to_start_and_end_string, '2000-01-05T00:12:33Z/2200-11-05T08:02:33.4Z';
  is $interval->to_start_and_duration_string, '2000-01-05T00:12:33Z/PT6337727400S';
  isa_ok $interval->start_date_time, 'Web::DateTime';
  is $interval->start_date_time->to_global_date_and_time_string,
      '2000-01-05T00:12:33Z';
  isa_ok $interval->end_date_time, 'Web::DateTime';
  is $interval->end_date_time->to_global_date_and_time_string,
      '2200-11-05T08:02:33.4Z';
  isa_ok $interval->duration, 'Web::DateTime::Duration';
  is $interval->duration->to_duration_string, 'PT6337727400.3999996185S';
  ok not $interval->is_date_time;
  ok $interval->is_interval;
  ok not $interval->is_time_zone;
  ok not $interval->is_duration;
  done $c;
} n => 12, name => 'new_from_start_and_end';

test {
  my $c = shift;
  my $dt1 = Web::DateTime::Parser->parse_global_date_and_time_string
      ('2000-01-05T00:12:33Z');
  my $duration = Web::DateTime::Parser->parse_duration_string
      ('20m 50s');
  my $interval = Web::DateTime::Interval->new_from_start_and_duration
      ($dt1, $duration);
  is $interval->to_start_and_end_string, '2000-01-05T00:12:33Z/2000-01-05T00:33:23Z';
  is $interval->to_start_and_duration_string, '2000-01-05T00:12:33Z/PT1250S';
  isa_ok $interval->start_date_time, 'Web::DateTime';
  is $interval->start_date_time->to_global_date_and_time_string,
      '2000-01-05T00:12:33Z';
  isa_ok $interval->end_date_time, 'Web::DateTime';
  is $interval->end_date_time->to_global_date_and_time_string,
      '2000-01-05T00:33:23Z';
  isa_ok $interval->duration, 'Web::DateTime::Duration';
  is $interval->duration->to_duration_string, 'PT1250S';
  done $c;
} n => 8, name => 'new_from_start_and_duration';

test {
  my $c = shift;
  my $dt1 = Web::DateTime::Parser->parse_global_date_and_time_string
      ('2200-11-05T09:02:33.4+01:00');
  my $dt2 = Web::DateTime::Parser->parse_global_date_and_time_string
      ('2200-11-05T09:02:33.4+01:00');
  my $interval = Web::DateTime::Interval->new_from_start_and_end ($dt1, $dt2);
  is $interval->to_start_and_end_string, '2200-11-05T08:02:33.4Z/2200-11-05T08:02:33.4Z';
  is $interval->to_start_and_duration_string, '2200-11-05T08:02:33.4Z/PT0S';
  isa_ok $interval->start_date_time, 'Web::DateTime';
  is $interval->start_date_time->to_global_date_and_time_string,
      '2200-11-05T08:02:33.4Z';
  isa_ok $interval->end_date_time, 'Web::DateTime';
  is $interval->end_date_time->to_global_date_and_time_string,
      '2200-11-05T08:02:33.4Z';
  isa_ok $interval->duration, 'Web::DateTime::Duration';
  is $interval->duration->to_duration_string, 'PT0S';
  done $c;
} n => 8, name => 'new_from_start_and_end 0';

test {
  my $c = shift;
  my $dt1 = Web::DateTime::Parser->parse_global_date_and_time_string
      ('2000-01-05T00:12:33Z');
  my $duration = Web::DateTime::Parser->parse_duration_string
      ('0.0s');
  my $interval = Web::DateTime::Interval->new_from_start_and_duration
      ($dt1, $duration);
  is $interval->to_start_and_end_string, '2000-01-05T00:12:33Z/2000-01-05T00:12:33Z';
  is $interval->to_start_and_duration_string, '2000-01-05T00:12:33Z/PT0S';
  isa_ok $interval->start_date_time, 'Web::DateTime';
  is $interval->start_date_time->to_global_date_and_time_string,
      '2000-01-05T00:12:33Z';
  isa_ok $interval->end_date_time, 'Web::DateTime';
  is $interval->end_date_time->to_global_date_and_time_string,
      '2000-01-05T00:12:33Z';
  isa_ok $interval->duration, 'Web::DateTime::Duration';
  is $interval->duration->to_duration_string, 'PT0S';
  done $c;
} n => 8, name => 'new_from_start_and_end 0';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
