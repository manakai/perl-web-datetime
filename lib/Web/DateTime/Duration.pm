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

sub seconds ($) {
  return $_[0]->{seconds};
} # seconds

sub months ($) {
  return $_[0]->{months} || 0;
} # months

sub to_duration_string ($) {
  return undef if $_[0]->{month};
  my $s = sprintf 'PT%.10fS', $_[0]->seconds;
  $s =~ s/\.0+S\z/S/;
  $s =~ s/\.([0-9]*[1-9])0+S\z/.$1S/;
  return $s;
} # to_duration_string

sub to_vevent_duration_string ($) {
  return undef if $_[0]->{month};
  my $s = sprintf 'PT%dS', $_[0]->seconds;
  return $s;
} # to_vevent_duration_string

sub to_xs_duration ($) {
  my $s = '';
  $s .= '-' if $_[0]->{negative};
  if ($_[0]->{month}) {
    $s .= sprintf 'P%dMT%.10fS',
        $_[0]->months, $_[0]->seconds;
  } else {
    $s .= sprintf 'PT%.10fS', $_[0]->seconds;
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
