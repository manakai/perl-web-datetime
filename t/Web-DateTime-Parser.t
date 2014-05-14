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

for my $test (
  [''],
  ['z'],
  ['1000.0'],
  ['0000', [{type => 'datetime:bad year', level => 'm', value => '0000'}]],
  ['2010-01'],
  ['H20'],
  ['20.01'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_year_string ($test->[0]);
    is $tz, undef;
    eq_or_diff \@error, $test->[1] || [{type => 'year:syntax error', level => 'm'}];
    done $c;
  } n => 2;
}

for my $test (
  [''],
  ['z'],
  ['1000.0'],
  ['2010-01'],
  ['01-00', [{type => 'datetime:bad day', level => 'm', value => '00'}]],
  ['01-32', [{type => 'datetime:bad day', level => 'm', value => '32'}]],
  ['02-30', [{type => 'datetime:bad day', level => 'm', value => '30'}]],
  ['00-30', [{type => 'datetime:bad month', level => 'm', value => '00'}]],
  ['13-30', [{type => 'datetime:bad month', level => 'm', value => '13'}]],
  ['001-30'],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $tz = $parser->parse_yearless_date_string ($test->[0]);
    is $tz, undef;
    eq_or_diff \@error, $test->[1] || [{type => 'date:syntax error', level => 'm'}];
    done $c;
  } n => 2;
}

for my $test (
  ['', undef],
  ['z', undef],
  ['1000.0', undef],
  ['-41s', undef],
  ['-PT31H31M', undef],
  ['41s' => 41, undef, [{type => 'duration:html duration', level => 'm'}]],
  ["10m\t30s" => 10*60+30, undef,
   [{type => 'duration:html duration', level => 'm'}]],
  ['420.400 s' => 420.4, undef,
   [{type => 'datetime:fractional second', level => 'm'},
    {type => 'duration:html duration', level => 'm'}]],
  [' PT132S', 132, [{type => 'duration:space', level => 'm'}]],
  ['32w21d' => 32*7*24*60*60+21*24*60*60, undef,
   [{type => 'duration:html duration', level => 'm'}]],
  ['0h' => 0, undef, [{type => 'duration:html duration', level => 'm'}]],
  ['42.44m' => undef],
  ['332.000s' => 332, undef,
   [{type => 'datetime:fractional second', level => 'm'},
    {type => 'duration:html duration', level => 'm'}]],
  ['32Y32M' => undef, [{type => 'duration:months', level => 'm'}]],
  ['32M' => 32*60, undef, [{type => 'duration:html duration', level => 'm'}]],
  ['T32M' => 32*60, [{type => 'duration:syntax error', level => 'm',
                      value => 'TM'}]],
  ['0Y32M' => undef, [{type => 'duration:months', level => 'm'}]],
  ['P32M' => undef, [{type => 'duration:months', level => 'm'}]],
  ['32M10M' => 42*60, undef,
   [{type => 'duration:html duration', level => 'm'}]],
  ['10s32M' => 32*60+10, undef,
   [{type => 'duration:html duration', level => 'm'}]],
  ['P10s32M' => 32*60+10, [{type => 'duration:case', level => 'm',
                            value => 's'},
                           {type => 'duration:syntax error', level => 'm',
                            value => 'PSM'}]],
  ['10d32M' => 10*24*60*60+32*60, undef,
   [{type => 'duration:html duration', level => 'm'}]],
  ['32MPT' => undef],
  ['32MT' => 32*60, [{type => 'duration:syntax error', level => 'm',
                      value => 'MT'}]],
  ['10.3d' => undef],
  ['PT42M31d' => 42*60+31*24*60*60, [{type => 'duration:case', level => 'm',
                                      value => 'd'},
                                     {type => 'duration:syntax error',
                                      level => 'm',
                                      value => 'PTMD'}]],
  ['P10h2h' => 12*60*60, [{type => 'duration:case',
                           value => 'h',
                           level => 'm'},
                          {type => 'duration:syntax error',
                           value => 'PHH',
                           level => 'm'}]],
  ['31Y' => undef, [{type => 'duration:months', level => 'm'}]],
  ['P21W' => 21*7*24*60*60, [{type => 'duration:syntax error',
                              value => 'PW',
                              level => 'm'}], []],
  ['PT21D' => 21*24*60*60, [{type => 'duration:syntax error',
                             value => 'PTD',
                             level => 'm'}]],
  ['P21WT31H' => 21*7*24*60*60+31*60*60,
   [{type => 'duration:syntax error',
     value => 'PWTH',
     level => 'm'}]],
  ['P21W31D' => 21*7*24*60*60+31*24*60*60,
   [{type => 'duration:syntax error',
     value => 'PWD',
     level => 'm'}]],
  ['PT12H3S' => 12*60*60+3, undef, [{type => 'duration:syntax error',
                                     value => 'PTHS',
                                     level => 'm'}]],
) {
  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_duration_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->months, 0;
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[2] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[2] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 4, name => ['parse_duration_string', $test->[0]];

  test {
    my $c = shift;
    my $parser = Web::DateTime::Parser->new;
    my @error;
    $parser->onerror (sub {
      push @error, {@_};
    });
    my $duration = $parser->parse_vevent_duration_string ($test->[0]);
    if (defined $test->[1]) {
      isa_ok $duration, 'Web::DateTime::Duration';
      is $duration && $duration->months, 0;
      is $duration && $duration->seconds, $test->[1];
      eq_or_diff \@error, $test->[3] || $test->[2] || [];
    } else {
      is $duration, undef;
      ok 1;
      ok 1;
      eq_or_diff \@error, $test->[3] || $test->[2] || [{type => 'duration:syntax error', level => 'm'}];
    }
    done $c;
  } n => 4, name => ['parse_vevent_duration_string', $test->[0]];
}

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
