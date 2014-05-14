use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Web::DateTime::Duration;

for my $test (
  [0],
  [1251523],
  [-31533 => 31533],
  [5213.55555],
  [0.0004],
  [40],
) {
  test {
    my $c = shift;
    my $duration = Web::DateTime::Duration->new_from_seconds ($test->[0]);
    is $duration->seconds, $test->[1] || $test->[0];
    is $duration->months, 0;
    is $duration->sign, $test->[0] < 0 ? -1 : +1;
    is $duration->to_duration_string, 'PT' . ($test->[1] || $test->[0]) . 'S';
    is $duration->to_xs_duration,
        ($test->[0] < 0 ? '-' : '') . 'PT' . ($test->[1] || $test->[0]) . 'S';
    is $duration->to_vevent_duration_string,
        'PT' . int ($test->[1] || $test->[0]) . 'S';
    ok not $duration->is_datetime;
    ok not $duration->is_period;
    ok not $duration->is_time_zone;
    ok $duration->is_duration;
    done $c;
  } n => 10, name => ['new_from_seconds'];
}

for my $test (
  [0, 0, +1],
  [1251523, 0, +1],
  [5213.55555, 0, +1],
  [0.0004, 0, +1],
  [40, 0, +1],
  [0, 422, +1],
  [0, 44, -1],
  [44, 41100, +1],
  [44, 41100, -1],
  [0, 0, -1],
) {
  test {
    my $c = shift;
    my $duration = Web::DateTime::Duration->new_from_seconds_and_months_and_sign
        ($test->[0], $test->[1], $test->[2]);
    is $duration->seconds, $test->[0];
    is $duration->months, $test->[1];
    is $duration->sign, $test->[2];
    if ($test->[1]) { # has months
      is $duration->to_duration_string, undef;
      is $duration->to_vevent_duration_string, undef;
      if ($test->[0]) {
        is $duration->to_xs_duration,
            ($test->[2] < 0 ? '-' : '') . 'P' . ($test->[1]) . 'MT' . ($test->[0]) . 'S';
      } else {
        is $duration->to_xs_duration,
            ($test->[2] < 0 ? '-' : '') . 'P' . ($test->[1]) . 'M';
      }
    } else {
      is $duration->to_duration_string, 'PT' . ($test->[0]) . 'S';
      is $duration->to_xs_duration,
          ($test->[2] < 0 ? '-' : '') . 'PT' . ($test->[0]) . 'S';
      is $duration->to_vevent_duration_string,
          $test->[1] ? undef : 'PT' . int ($test->[0]) . 'S';
    }
    done $c;
  } n => 6, name => ['new_from_seconds_and_months_and_sign'];
}

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
