package Web::DateTime::Period;
use strict;
use warnings;
our $VERSION = '1.0';

sub new_from_datetimes ($$$) {
  return bless {start_datetime => $_[1], end_datetime => $_[2]}, $_[0];
} # new_from_datetimes

sub new_from_datetime_and_duration ($$$) {
  return bless {start_datetime => $_[1], duration => $_[2]}, $_[0];
} # new_from_datetime_and_duration

sub is_datetime ($) { 0 }
sub is_time_zone ($) { 0 }
sub is_duration ($) { 0 }
sub is_period ($) { 1 }

sub start_datetime ($) {
  return $_[0]->{start_datetime};
} # start_datetime

sub end_datetime ($) {
  my $self = $_[0];
  return $self->{end_datetime} ||= do {
    (ref $self->{start_datetime})->new_from_unix_time ($self->{start_datetime}->to_unix_number + $self->{duration}->seconds);
  };
} # end_datetime

sub duration ($) {
  my $self = $_[0];
  return $self->{duration} ||= do {
    require Web::DateTime::Duration;
    Web::DateTime::Duration->new_from_seconds ($self->{end_datetime}->to_unix_number - $self->{start_datetime}->to_unix_number);
  };
} # duration

sub to_datetimes_string ($) {
  my $self = $_[0];
  return
      $self->start_datetime->to_global_date_and_time_string .
      '/' .
      $self->end_datetime->to_global_date_and_time_string;
} # to_datetimes_string

sub to_datetime_and_duration_string ($) {
  my $self = $_[0];
  return
      $self->start_datetime->to_global_date_and_time_string .
      '/' .
      $self->duration->to_vevent_duration_string;
} # to_datetime_and_duration_string

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
