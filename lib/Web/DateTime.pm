package Web::DateTime;
use strict;
use warnings;
our $VERSION = '5.0';
use Carp qw(croak);
use Time::Local;

sub new_from_unix_time ($$) {
  my $self = bless {value => 0+$_[1]}, $_[0];
  if ($self->{value} != int $self->{value}) {
    if ($self->{value} >= 0) {
      $self->{second_fraction} = $self->{value} - int $self->{value};
      $self->{value} = int $self->{value};
    } else {
      $self->{second_fraction} = $self->{value} - (-(int abs $self->{value}) - 1);
      $self->{value} = -(int abs $self->{value}) - 1;
    }
  }
  require Web::DateTime::TimeZone;
  $self->{tz} = Web::DateTime::TimeZone->new_from_offset (0);
  return $self;
} # new_from_unix_time

sub new_from_object ($$) {
  if (UNIVERSAL::isa ($_[1], 'DateTime')) {
    my $self = bless {value => $_[1]->epoch}, $_[0];
    my $f = $_[1]->fractional_second - $_[1]->second;
    if ($f) {
      $self->{second_fraction} = $f;
    }
    unless ($_[1]->time_zone->is_floating) {
      require Web::DateTime::TimeZone;
      $self->{tz} = Web::DateTime::TimeZone->new_from_offset ($_[1]->offset);
    }
    return $self;
  } elsif (UNIVERSAL::isa ($_[1], 'Time::Piece')) {
    my $self = bless {value => $_[1]->epoch}, $_[0];
    require Web::DateTime::TimeZone;
    $self->{tz} = Web::DateTime::TimeZone->new_from_offset
        ($_[1]->tzoffset->seconds);
    return $self;
  } else {
    croak "Can't create |Web::DateTime| from a |" . (ref $_[1]) . "|";
  }
} # new_from_object

sub _is_leap_year ($) {
  return ($_[0] % 400 == 0 or ($_[0] % 4 == 0 and $_[0] % 100 != 0));
} # _is_leap_year

## <http://www.whatwg.org/specs/web-apps/current-work/#week-number-of-the-last-day>
sub _last_week_number ($) {
  my $jan1_dow = [gmtime Time::Local::timegm (0, 0, 0, 1, 1 - 1, $_[0])]->[6];
  return ($jan1_dow == 4 or
          ($jan1_dow == 3 and _is_leap_year ($_[0]))) ? 53 : 52;
} # _last_week_number

sub _week_year_diff ($) {
  my $jan1_dow = [gmtime Time::Local::timegm (0, 0, 0, 1, 1 - 1, $_[0])]->[6];
  if ($jan1_dow <= 4) {
    return $jan1_dow - 1;
  } else {
    return $jan1_dow - 8;
  }
} # _week_year_diff

sub to_time_string ($) {
  my $self = shift;
  return sprintf '%02d:%02d:%02d%s',
      $self->utc_hour, $self->utc_minute,
      $self->utc_second, $self->second_fraction_string;
} # to_time_string

sub to_week_string ($) {
  my $self = shift;
  return sprintf '%04d-W%02d', $self->utc_week_year, $self->utc_week;
} # to_week_string

sub to_month_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d', $self->utc_year, $self->utc_month;
} # to_month_string

sub to_date_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02d',
      $self->utc_year, $self->utc_month, $self->utc_day;
} # to_date_string

sub to_local_date_and_time_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s',
      $self->year, $self->month, $self->day,
      $self->hour, $self->minute, $self->second, $self->second_fraction_string;
} # to_local_date_and_time_string

sub to_global_date_and_time_string ($) {
  my $self = shift;
  ## Always in UTC
  return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%sZ',
      $self->utc_year, $self->utc_month, $self->utc_day,
      $self->utc_hour, $self->utc_minute,
      $self->utc_second, $self->second_fraction_string;
} # to_global_date_and_time_string

sub to_time_zoned_global_date_and_time_string ($) {
  my $self = shift;
  return $self->to_local_date_and_time_string . (
    defined $self->{tz} ? $self->{tz}->to_offset_string : 'Z'
  );
} # to_time_zoned_global_date_and_time_string

sub to_date_string_with_optional_time ($) {
  my $self = $_[0];
  if (defined $self->{tz}) {
    return $self->to_time_zoned_global_date_and_time_string;
  } else {
    return $self->to_date_string;
  }
} # to_date_string_with_optional_time

sub time_zone ($) {
  return $_[0]->{tz}; # or undef
} # time_zone

sub utc_week ($) {
  my $self = shift;

  if (defined $self->{cache}->{utc_week}) {
    return $self->{cache}->{utc_week};
  }

  my $year = $self->utc_year;

  my $jan1 = __PACKAGE__->_create ($year, 1, 1, 0, 0, 0, 0, undef, undef);

  my $days = $self->to_unix_integer - $jan1->to_unix_integer;
  $days /= 24 * 3600;

  my $week_year_diff = _week_year_diff ($year);
  $days += $week_year_diff;

  my $week = int ($days / 7) + 1;
  
  if ($days < 0) {
    $year--;
    $week = _last_week_number ($year);
  } elsif ($week > _last_week_number ($year)) {
    $year++;
    $week = 1;
  }
  
  $self->{cache}->{utc_week_year} = $year;
  $self->{cache}->{utc_week} = $week;

  return $week;
} # utc_week

sub utc_week_year ($) {
  my $self = shift;
  $self->utc_week;
  return $self->{cache}->{utc_week_year};
} # utc_week_year

## <http://www.whatwg.org/specs/web-apps/current-work/#month-state-(type=month)>
sub to_html_month_number ($) {
  my $self = shift;
  ## Note that the spec does not explicitly define what should be
  ## defined when the year is less than 1970.
  my $y = $self->year - 1970;
  my $m = $self->month - 1;
  return $y * 12 + $m;
} # to_html_month_number

my $unix_epoch = Time::Local::timegm (0, 0, 0, 1, 1 - 1, 1970);

sub _create ($$$$$$$$$$;$) {
  my $self = bless {}, shift;
  my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm, $diff) = @_;
  
  $self->{value} = Time::Local::timegm_nocheck
      ($s, $m - ($zm || 0), $h - ($zh|| 0), $d, $M-1, $y);
  if (defined $zh) {
    require Web::DateTime::TimeZone;
    $self->{tz} = Web::DateTime::TimeZone->new_from_offset
        (($zh >= 0 ? +1 : -1) * ((abs $zh) * 60 * 60 + $zm * 60));
  }
  
  if ($diff) {
    my $v = $self->{value} . $sf;
    $v += $diff / 1000;
    my $int_v = int $v;
    if ($int_v != $v) {
      if ($v > 0) {
        $self->{value} = $int_v;
        $sf = $v - $int_v;
      } else {
        $self->{value} = $int_v - 1;
        $sf = $v - $int_v - 1;
      }
    } else {
      $self->{value} = $v;
      $sf = '';
    }
  }

  $self->{second_fraction} = $sf;

  return $self;
} # _set

sub second_fraction_string ($) {
  my $self = shift;
  if ($self->{second_fraction}) {
    my $v = $self->{second_fraction};
    unless (substr ($v, 0, 1) eq '.') {
      $v = sprintf '%.100f', $v;
      $v = substr $v, 1;
    }
    $v = substr $v, 1;
    $v =~ s/0+\z//;
    return length $v ? '.' . $v :'';
  } else {
    return '';
  }
} # second_fraction_string

sub _utc_time ($) {
  my $self = shift;
  $self->{cache}->{utc_time} = [gmtime ($self->{value} || 0)];
} # _utc_time

sub _local_time ($) {
  my $self = shift;
  $self->{cache}->{local_time} = [gmtime (($self->{value} || 0) + (defined $self->{tz} ? $self->{tz}->offset_as_seconds : 0))];
} # _local_time

sub year ($) {
  my $self = shift;
  $self->_local_time unless defined $self->{cache}->{local_time};
  return $self->{cache}->{local_time}->[5] + 1900;
} # year

sub month ($) {
  my $self = shift;
  $self->_local_time unless defined $self->{cache}->{local_time};
  return $self->{cache}->{local_time}->[4] + 1;
} # month

sub day ($) {
  my $self = shift;
  $self->_local_time unless defined $self->{cache}->{local_time};
  return $self->{cache}->{local_time}->[3];
} # day

sub day_of_week ($) {
  my $self = shift;
  $self->_local_time unless defined $self->{cache}->{local_time};
  return $self->{cache}->{local_time}->[6]; # 0..6
} # day_of_week

sub hour ($) {
  my $self = shift;
  $self->_local_time unless defined $self->{cache}->{local_time};
  return $self->{cache}->{local_time}->[2];
} # hour

sub minute ($) {
  my $self = shift;
  $self->_local_time unless defined $self->{cache}->{local_time};
  return $self->{cache}->{local_time}->[1];
} # minute

sub second ($) {
  my $self = shift;
  $self->_local_time unless defined $self->{cache}->{local_time};
  return $self->{cache}->{local_time}->[0];
} # second

sub fractional_second ($) {
  my $self = shift;
  return $self->second + $self->{second_fraction};
} # fractional_second

sub utc_year ($) {
  my $self = shift;
  $self->_utc_time unless defined $self->{cache}->{utc_time};
  return $self->{cache}->{utc_time}->[5] + 1900;
} # utc_year

sub utc_month ($) {
  my $self = shift;
  $self->_utc_time unless defined $self->{cache}->{utc_time};
  return $self->{cache}->{utc_time}->[4] + 1;
} # utc_month

sub utc_day ($) {
  my $self = shift;
  $self->_utc_time unless defined $self->{cache}->{utc_time};
  return $self->{cache}->{utc_time}->[3];
} # utc_day

sub utc_day_of_week ($) {
  my $self = shift;
  $self->_utc_time unless defined $self->{cache}->{utc_time};
  return $self->{cache}->{utc_time}->[6]; # 0..6
} # utc_day_of_week

sub utc_hour ($) {
  my $self = shift;
  $self->_utc_time unless defined $self->{cache}->{utc_time};
  return $self->{cache}->{utc_time}->[2];
} # utc_hour

sub utc_minute ($) {
  my $self = shift;
  $self->_utc_time unless defined $self->{cache}->{utc_time};
  return $self->{cache}->{utc_time}->[1];
} # utc_minute

sub utc_second ($) {
  my $self = shift;
  $self->_utc_time unless defined $self->{cache}->{utc_time};
  return $self->{cache}->{utc_time}->[0];
} # utc_second

sub utc_fractional_second ($) {
  my $self = shift;
  return $self->utc_second + $self->{second_fraction};
} # utc_fractional_second

sub to_html_number ($) {
  my $self = shift;
  my $int = $self->{value} - $unix_epoch;
  my $frac = $self->second_fraction_string . '00000';
  $frac = substr $frac, 1; # remove leading "."
  substr ($frac, 4, 0) = '.';
  $frac =~ s/0+\z//;
  $frac =~ s/\.\z//;
  return $int . $frac;
} # to_html_number

sub to_unix_integer ($) {
  my $self = shift;
  return $self->{value} - $unix_epoch;
} # to_unix_integer

sub to_datetime ($) {
  my $self = shift;
  require DateTime;
  return DateTime->from_epoch
      (epoch => $self->to_unix_integer,
       time_zone => defined $self->{tz} ? $self->{tz}->to_offset_string : 'floating');
} # to_datetime

sub to_time_piece_gm ($) {
  my $self = $_[0];
  require Time::Piece;
  return Time::Piece::gmtime ($self->to_unix_integer);
} # to_time_piece_gm

sub to_time_piece_local ($) {
  my $self = $_[0];
  require Time::Piece;
  return Time::Piece::localtime ($self->to_unix_integer);
} # to_time_piece_local

# XXX normalized serializer
# XXX duration formats
# XXX period formats
# XXX XML Schema datatypes
# XXX microdata vocab datetime
# XXX OGP datetime
# XXX RFC 3339 date-time
# XXX document.lastModified
# XXX HTTP datetime
# XXX MySQL datetime

# XXX JavaScript timestamp parser/serializer

1;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
