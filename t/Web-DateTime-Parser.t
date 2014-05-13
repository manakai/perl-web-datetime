use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Differences;
use Web::DateTime::Parser;

for my $test (
  ['Z', 0],
  ['+00:00', 0],
  ['-00:12', -12*60],
  ['+03:12', 3*60*60+12*60],
  ['-13:12', -(13*60*60+12*60)],
  ['-00:00', 0, [{type => 'datetime:-00:00', level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_time_zone_offset_string ($test->[0]);
    isa_ok $tz, 'Web::DateTime::TimeZone';
    is $tz->offset_as_seconds, $test->[1];
    eq_or_diff \@error, $test->[2] || [];
    done $c;
  } n => 3;
}

for my $test (
  [''],
  ['z'],
  ['+0000'],
  ['12:00'],
  ['+24:00', [{type => 'datetime:bad timezone hour', level => 'm', value => 24}]],
  ['-24:00', [{type => 'datetime:bad timezone hour', level => 'm', value => 24}]],
  ['+20:60', [{type => 'datetime:bad timezone minute', level => 'm', value => 60}]],
  ['+20:600'],
  ['+200:60'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_time_zone_offset_string ($test->[0]);
    is $tz, undef;
    eq_or_diff \@error, $test->[1] || [{type => 'tz:syntax error', level => 'm'}];
    done $c;
  } n => 2;
}

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
