package Web::DateTime::Duration;
use strict;
use warnings;
our $VERSION = '1.0';

sub new_from_seconds ($$) {
  my $self = bless {seconds => $_[1]}, $_[0];
  if ($_[1] < 0) {
    $self->{negative} = 1;
    $self->{seconds} *= -1;
  }
  return $self;
} # new_from_seconds

sub new_from_seconds_and_months_and_sign ($$$$) {
  my $self = bless {seconds => $_[1],
                    months => $_[2]}, $_[0];
  $self->{negative} = 1 if $_[3] < 0;
  return $self;
} # new_from_seconds_and_months_and_sign

sub is_datetime ($) { 0 }
sub is_time_zone ($) { 0 }
sub is_duration ($) { 1 }
sub is_period ($) { 0 }

sub seconds ($) {
  return $_[0]->{seconds};
} # seconds

sub months ($) {
  return $_[0]->{months} || 0;
} # months

sub sign ($) {
  return $_[0]->{negative} ? -1 : +1;
} # sign

sub to_duration_string ($) {
  return undef if $_[0]->months;
  my $s = sprintf 'PT%.10fS', $_[0]->seconds;
  $s =~ s/\.0+S\z/S/;
  $s =~ s/\.([0-9]*[1-9])0+S\z/.$1S/;
  return $s;
} # to_duration_string

sub to_vevent_duration_string ($) {
  return undef if $_[0]->months;
  my $s = sprintf 'PT%dS', $_[0]->seconds;
  return $s;
} # to_vevent_duration_string

sub to_xs_duration ($) {
  my $self = $_[0];
  my $s = '';
  $s .= '-' if $self->sign < 0;
  my $m = $self->months;
  my $sec = $self->seconds;
  if ($m) {
    if ($sec) {
      $s .= sprintf 'P%dMT%.10fS', $m, $sec;
    } else {
      $s .= sprintf 'P%dM', $m;
    }
  } else {
    $s .= sprintf 'PT%.10fS', $sec;
  }
  $s =~ s/\.0+S\z/S/;
  $s =~ s/\.([0-9]*[1-9])0+S\z/.$1S/;
  return $s;
} # to_xs_duration

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
