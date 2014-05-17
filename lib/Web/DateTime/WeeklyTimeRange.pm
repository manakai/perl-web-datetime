package Web::DateTime::WeeklyTimeRange;
use strict;
use warnings;
our $VERSION = '1.0';

sub new_from_weekdays_and_time_ranges ($$$) {
  return bless {weekdays => $_[1], ranges => $_[2]}, $_[0];
} # new_from_weekdays_and_time_ranges

# $self->{weekdays}->[0..6] = boolean
# $self->{ranges} = [
#   [$minutes, $minutes],
#   ...,
# ]

my @Wday = qw[Su Mo Tu We Th Fr Sa];

sub to_weekly_time_range_string ($) {
  my $self = $_[0];
  my $wday = join ',', map { $Wday[$_] } grep { $self->{weekdays}->[$_] } 0..$#{$self->{weekdays}};
  my $times = join ',', map {
    sprintf '%02d:%02d-%02d:%02d',
        $_->[0] / 60, $_->[0] % 60,
        $_->[1] / 60, $_->[1] % 60;
  } @{$self->{ranges}};
  return join ' ', $wday, length $times ? $times : ();
} # to_weekly_time_range_string

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
