package Web::DateTime::TimeZone;
use strict;
use warnings;
our $VERSION = '1.0';

sub new_utc ($) {
  return bless {offset => 0}, $_[0];
} # new_utc

sub new_from_offset ($) {
  return bless {offset => $_[1]}, $_[0];
} # new_from_offset

sub offset_as_seconds ($) {
  return $_[0]->{offset};
} # offset_as_seconds

sub offset_sign ($) {
  return $_[0]->{offset} >= 0 ? +1 : -1;
} # offset_sign

sub offset_hour ($) {
  return int ((abs $_[0]->{offset}) / 60 / 60);
} # offset_hour

sub offset_minute ($) {
  return int (((abs $_[0]->{offset}) / 60) % 60);
} # offset_minute

sub to_offset_string ($) {
  my $self = $_[0];
  if ($self->{offset} == 0) {
    return 'Z';
  } else {
    return sprintf '%s%02d:%02d',
        $self->offset_sign > 0 ? '+' : '-',
        $self->offset_hour,
        $self->offset_minute;
  }
} # to_offset_string

1;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
