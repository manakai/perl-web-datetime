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
    is $duration->to_duration_string, 'PT' . ($test->[1] || $test->[0]) . 'S';
    is $duration->to_xs_duration,
        ($test->[0] < 0 ? '-' : '') . 'PT' . ($test->[1] || $test->[0]) . 'S';
    is $duration->to_vevent_duration_string,
        'PT' . int ($test->[1] || $test->[0]) . 'S';
    done $c;
  } n => 5, name => ['new_from_seconds'];
}

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
