use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Web::DateTime::WeeklyTimeRange;

for my $test (
  [[], [] => ''],
  [[1], [] => 'Su'],
  [[1, 1], [] => 'Su,Mo'],
  [[1, 1, 0, 0, 0, 1], [] => 'Su,Mo,Fr'],
  [[1, 1, 0, 0, 0, 1, 1], [] => 'Su,Mo,Fr,Sa'],
  [[0, 0, 1, 1, 1, 0, 0], [] => 'Tu,We,Th'],
  [[0, 0, 1, 1, 1, 0, 0], [[12 => 333]] => 'Tu,We,Th 00:12-05:33'],
  [[0, 0, 1, 1, 1, 0, 0], [[12 => 333], [31 => 66]] => 'Tu,We,Th 00:12-05:33,00:31-01:06'],
) {
  test {
    my $c = shift;
    my $wtr = Web::DateTime::WeeklyTimeRange->new_from_weekdays_and_time_ranges
        ($test->[0], $test->[1]);
    is $wtr->to_weekly_time_range_string, $test->[2];
    done $c;
  } n => 1, name => ['to_weekly_time_range_string'];
}

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
