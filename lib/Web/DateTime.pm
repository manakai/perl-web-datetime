package Web::DateTime;
use strict;
use warnings;
our $VERSION = '7.0';
use Carp qw(croak);
use POSIX qw(floor);

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
  $self->{has_component} = {year => 1, month => 1, day => 1,
                            time => 1, offset => 1};
  return $self;
} # new_from_unix_time

sub new_from_jd ($$) {
  return $_[0]->new_from_unix_time (($_[1] - 2440587.5) * 24 * 60 * 60);
} # new_from_jd

sub new_from_mjd ($$) {
  return $_[0]->new_from_unix_time
      (($_[1] + 2400000.5 - 2440587.5) * 24 * 60 * 60);
} # new_from_mjd

sub new_from_object ($$) {
  if (UNIVERSAL::isa ($_[1], 'DateTime')) {
    my $self = bless {value => $_[1]->epoch}, $_[0];
    my $f = $_[1]->fractional_second - $_[1]->second;
    if ($f) {
      $self->{second_fraction} = $f;
    }
    $self->{has_component} = {year => 1, month => 1, day => 1, time => 1};
    unless ($_[1]->time_zone->is_floating) {
      require Web::DateTime::TimeZone;
      $self->{tz} = Web::DateTime::TimeZone->new_from_offset ($_[1]->offset);
      $self->{has_component}->{offset} = 1;
    }
    return $self;
  } elsif (UNIVERSAL::isa ($_[1], 'Time::Piece')) {
    my $self = bless {value => $_[1]->epoch}, $_[0];
    require Web::DateTime::TimeZone;
    $self->{tz} = Web::DateTime::TimeZone->new_from_offset
        ($_[1]->tzoffset->seconds);
    $self->{has_component} = {year => 1, month => 1, day => 1,
                              time => 1, offset => 1};
    return $self;
  } else {
    croak "Can't create |Web::DateTime| from a |" . (ref $_[1]) . "|";
  }
} # new_from_object

sub new_from_components ($$$$$$$) {
  my ($class, $year, $month, $day, $hour, $minute, $second) = @_;
  my $components = {year => defined $year,
                    month => defined $month,
                    day => defined $day,
                    time => defined $hour};
  $second ||= 0;
  my $sec_i = int $second;
  my $sec_f = $second - $sec_i;
  return $class->_create
      ($components,
       defined $year ? $year : 1970,
       defined $month ? $month : 1,
       defined $day ? $day : 1,
       $hour || 0, $minute || 0, $sec_i, $sec_f,
       undef, undef);
} # new_from_components

{
  ## Derived from |Time::Local|
  ## <http://cpansearch.perl.org/src/DROLSKY/Time-Local-1.2300/lib/Time/Local.pm>.

  use constant SECS_PER_MINUTE => 60;
  use constant SECS_PER_HOUR   => 3600;
  use constant SECS_PER_DAY    => 86400;

  my %Cheat;
  my $Epoc = 0;
  $Epoc = _daygm( gmtime(0) );
  %Cheat = ();

  sub _daygm {

    # This is written in such a byzantine way in order to avoid
    # lexical variables and sub calls, for speed
    return $_[3] + (
        $Cheat{ pack( 'ss', @_[ 4, 5 ] ) } ||= do {
            my $month = ( $_[4] + 10 ) % 12;
            my $year  = $_[5] + 1900 - int($month / 10);

            ( ( 365 * $year )
              + floor( $year / 4 )
              - floor( $year / 100 )
              + floor( $year / 400 )
              + floor( ( ( $month * 306 ) + 5 ) / 10 )
            )
            - $Epoc;
        }
    );
  }

  sub timegm_nocheck {
    my ( $sec, $min, $hour, $mday, $month, $year ) = @_;

    my $days = _daygm( undef, undef, undef, $mday, $month, $year - 1900);

    return $sec
           + ( SECS_PER_MINUTE * $min )
           + ( SECS_PER_HOUR * $hour )
           + ( SECS_PER_DAY * $days );
  }
}

my $unix_epoch = timegm_nocheck (0, 0, 0, 1, 1 - 1, 1970);

sub _create ($$$$$$$$$$$;$$) {
  my $self = bless {}, shift;
  my ($type, $y, $M, $d, $h, $m, $s, $sf, $zh, $zm, $diff, $julian) = @_;
  $self->{has_component} = $type;
  
  $zm *= -1 if defined $zh and $zh =~ /^-/;
  if ($M > 12 || $M < 1) {
    $M--;
    $y += floor ($M / 12);
    $M = $M % 12;
    $M++;
  }

  if ($julian) {
    $y += floor (($M - 3) / 12);
    my $month = ($M - 3) % 12;
    my $n = $d - 1 + floor ((153 * $month + 2) / 5) + 365 * $y + floor ($y / 4);
    $self->{value} = ($n - 678883 + 2400000.5 - 2440587.5) * 24 * 60 * 60
                   + ($h - ($zh || 0)) * 60 * 60
                   + ($m - ($zm || 0)) * 60
                   + $s;
  } else {
    $self->{value} = timegm_nocheck
        ($s, $m - ($zm || 0), $h - ($zh || 0), $d, $M-1, $y);
  }

  if (defined $zh) {
    require Web::DateTime::TimeZone;
    $self->{tz} = Web::DateTime::TimeZone->new_from_offset
        (($zh =~ /^-/ ? -1 : +1) * ((abs $zh) * 60 * 60 + (abs $zm) * 60));
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
} # _create

sub is_date_time ($) { 1 }
sub is_time_zone ($) { 0 }
sub is_duration ($) { 0 }
sub is_interval ($) { 0 }

sub has_component ($$) {
  return $_[0]->{has_component}->{$_[1]};
} # has_component

sub _is_leap_year ($) {
  return ($_[0] % 400 == 0 or ($_[0] % 4 == 0 and $_[0] % 100 != 0));
} # _is_leap_year

## <http://www.whatwg.org/specs/web-apps/current-work/#week-number-of-the-last-day>
sub _last_week_number ($) {
  my $jan1_dow = [gmtime timegm_nocheck (0, 0, 0, 1, 1 - 1, $_[0])]->[6];
  return ($jan1_dow == 4 or
          ($jan1_dow == 3 and _is_leap_year ($_[0]))) ? 53 : 52;
} # _last_week_number

sub _week_year_diff ($) {
  my $jan1_dow = [gmtime timegm_nocheck (0, 0, 0, 1, 1 - 1, $_[0])]->[6];
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

sub to_shortest_time_string ($) {
  my $s = $_[0]->to_time_string;
  $s =~ s/\.0+\z//;
  $s =~ s/(\.[0-9]*[1-9])0+\z/$1/;
  $s =~ s/:00\z//;
  return $s;
} # to_shortest_time_string

# XXX How y < 1 (which is not allowed in HTML) should be serialized?
# undef should be returned?

sub to_week_string ($) {
  my $self = shift;
  return sprintf '%04d-W%02d', $self->utc_week_year, $self->utc_week;
} # to_week_string

sub to_month_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d', $self->utc_year, $self->utc_month;
} # to_month_string

sub to_year_string ($) {
  return sprintf '%04d', $_[0]->utc_year;
} # to_year_string

sub to_date_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02d',
      $self->utc_year, $self->utc_month, $self->utc_day;
} # to_date_string

sub to_yearless_date_string ($) {
  my $self = shift;
  return sprintf '--%02d-%02d',
      $self->utc_month, $self->utc_day;
} # to_yearless_date_string

sub to_local_date_and_time_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s',
      $self->year, $self->month, $self->day,
      $self->hour, $self->minute, $self->second, $self->second_fraction_string;
} # to_local_date_and_time_string

sub to_normalized_local_date_and_time_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02dT%s',
      $self->year, $self->month, $self->day, $self->to_shortest_time_string;
} # to_normalized_local_date_and_time_string

sub to_global_date_and_time_string ($) {
  my $self = shift;
  ## Always in UTC
  return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%sZ',
      $self->utc_year, $self->utc_month, $self->utc_day,
      $self->utc_hour, $self->utc_minute,
      $self->utc_second, $self->second_fraction_string;
} # to_global_date_and_time_string

sub to_normalized_forced_utc_global_date_and_time_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02dT%sZ',
      $self->utc_year, $self->utc_month, $self->utc_day,
      $self->to_shortest_time_string;
} # to_normalized_forced_utc_global_date_and_time_string

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

sub to_http_date_string ($) {
  my $self = $_[0];
  return sprintf '%s, %02d %s %04d %02d:%02d:%02d GMT',
      [qw(Sun Mon Tue Wed Thu Fri Sat Sun)]->[$self->utc_day_of_week],
      $self->utc_day,
      [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)]->[$self->utc_month - 1],
      $self->utc_year,
      $self->utc_hour, $self->utc_minute, $self->utc_second;
} # to_http_date_string

sub to_rss2_date_time_string ($) {
  my $self = $_[0];
  return sprintf '%s, %02d %s %04d %02d:%02d:%02d +0000',
      [qw(Sun Mon Tue Wed Thu Fri Sat Sun)]->[$self->utc_day_of_week],
      $self->utc_day,
      [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)]->[$self->utc_month - 1],
      $self->utc_year,
      $self->utc_hour, $self->utc_minute, $self->utc_second;
} # to_rss2_date_time_string

sub to_document_last_modified_string ($) {
  my $self = $_[0];
  return sprintf '%02d/%02d/%04d %02d:%02d:%02d',
      $self->month, $self->day, $self->year,
      $self->hour, $self->minute, $self->second;
} # to_document_last_modified_string

sub to_manakai_year_string ($) {
  my $y = $_[0]->year;
  if ($y < 0) {
    return sprintf '-%04d', -$y;
  } else {
    return sprintf '%04d', $y;
  }
} # to_manakai_year_string

sub to_ymd_string ($) {
  my $y = $_[0]->year;
  if ($y < 0) {
    return sprintf '-%04d-%02d-%02d', -$y, $_[0]->month, $_[0]->day;
  } else {
    return sprintf '%04d-%02d-%02d', $y, $_[0]->month, $_[0]->day;
  }
} # to_ymd_string

sub to_julian_ymd_string ($) {
  my $y = $_[0]->julian_year;
  if ($y < 0) {
    return sprintf '-%04d-%02d-%02d', -$y, $_[0]->julian_month, $_[0]->julian_day;
  } else {
    return sprintf '%04d-%02d-%02d', $y, $_[0]->julian_month, $_[0]->julian_day;
  }
} # to_julian_ymd_string

sub time_zone ($) {
  return $_[0]->{tz}; # or undef
} # time_zone

sub set_time_zone ($$) {
  delete $_[0]->{cache};
  $_[0]->{tz} = $_[1];
} # set_time_zone

sub utc_week ($) {
  my $self = shift;

  if (defined $self->{cache}->{utc_week}) {
    return $self->{cache}->{utc_week};
  }

  my $year = $self->utc_year;

  my $jan1 = __PACKAGE__->_create ({}, $year, 1, 1, 0, 0, 0, 0, undef, undef);

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

## <https://www.whatwg.org/specs/web-apps/current-work/#month-state-(type=month)>
sub to_html_month_number ($) {
  my $self = shift;
  ## HTML Standard is not clear on the sign of the number when
  ## |$self->year < 1970|...
  my $y = $self->year - 1970;
  my $m = $self->month - 1;
  return $y * 12 + $m;
} # to_html_month_number

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

sub _julian ($) {
  my $self = $_[0];
  return $self->{cache}->{julian} ||= do {
    my $mjd = $self->to_mjd;
    my $n = $mjd + 678883;
    my $e = 4 * $n + 3;
    my $h = 5 * floor ( ($e % 1461) / 4 ) + 2;
    my $D = floor (($h % 153) / 5) + 1;
    my $M = floor ($h / 153) + 3;
    my $Y = floor ($e / 1461);
    if ($M > 12) {
      $M -= 12;
      $Y++;
    }
    [$Y, $M, $D];
  };
} # _julian

sub julian_year ($) {
  return $_[0]->_julian->[0];
} # julian_year

sub julian_month ($) {
  return $_[0]->_julian->[1];
} # julian_month

sub julian_day ($) {
  return $_[0]->_julian->[2];
} # julian_day

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
  return $self->to_unix_number * 1000;
} # to_html_number

sub to_unix_integer ($) {
  my $self = shift;
  return $self->{value} - $unix_epoch;
} # to_unix_integer

sub to_unix_number ($) {
  my $self = shift;
  my $value = $self->{value} - $unix_epoch;
  my $frac = $self->second_fraction_string;
  if (length $frac) {
    $frac = '0' . $frac;
  } else {
    $frac = 0;
  }
  return $value + $frac;
} # to_unix_number

sub to_jd ($) {
  return $_[0]->to_unix_number / (24*60*60) + 2440587.5;
} # to_jd

sub to_mjd ($) {
  return $_[0]->to_jd - 2400000.5;
} # to_mjd

sub to_rd ($) {
  return $_[0]->to_jd - 1721424.5;
} # to_rd

sub to_date_time ($) {
  my $self = shift;
  require DateTime;
  return DateTime->from_epoch
      (epoch => $self->to_unix_number,
       time_zone => defined $self->{tz} ? $self->{tz}->to_offset_string : 'floating');
} # to_date_time

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

1;

=head1 LICENSE

Copyright 2008-2016 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program partially derived from L<Time::Local>: "Copyright (c)
1997-2003 Graham Barr, 2003-2007 David Rolsky.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself."

=cut
