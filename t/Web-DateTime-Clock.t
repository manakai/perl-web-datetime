use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Web::DateTime::Clock;

test {
  my $c = shift;
  my $clock = Web::DateTime::Clock->realtime_clock;
  my $time = $clock->();
  ok $time;
  done $c;
} n => 1, name => 'realtime_clock';

test {
  my $c = shift;
  my $clock = Web::DateTime::Clock->monotonic_clock;
  my $time = $clock->();
  ok $time, $time;
  my $time2 = $clock->();
  ok $time2, $time2;
  ok $time < $time2;
  done $c;
} n => 3, name => 'monotonic_clock';

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
