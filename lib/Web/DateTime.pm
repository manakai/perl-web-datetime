package Web::DateTime;
use strict;
use warnings;
our $VERSION = '3.0';
use Time::Local;

sub new ($) {
  return bless {}, $_[0];
} # new

sub onerror ($;$) {
  if (@_ > 1) {
    $_[0]->{onerror} = $_[1];
  }
  return $_[0]->{onerror} ||= sub {
    my %opt = @_;
    my @msg = ($opt{type});
    push @msg, $opt{value} if defined $opt{value};
    warn join '; ', @msg, "\n";
  };
} # onerror

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

sub parse_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)?
  \z/x) {
    my ($h, $m, $s, $sf) = ($1, $2, $3, $4);
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return $self->_reset if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return $self->_reset if $m > 59;
    $s ||= 0;
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return $self->_reset if $s > 59;
    $sf = defined $sf ? $sf : '';
    return $self->_set (1970, 1, 1, $h, $m, $s, $sf, undef, undef);
  } else {
    $self->onerror->(type => 'time:syntax error',
                     level => 'm');
    return $self->_reset;
  }
} # parse_time_string

sub to_time_string ($) {
  my $self = shift;
  return sprintf '%02d:%02d:%02d%s',
      $self->utc_hour, $self->utc_minute,
      $self->utc_second, $self->second_fraction_string;
} # to_time_string

sub parse_week_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4,})-W([0-9]{2})\z/x) {
    my ($y, $w) = ($1, $2);
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return $self->_reset if $y == 0;
    $self->onerror->(type => 'week:bad week',
                     value => $w,
                     level => 'm'), return $self->_reset
        if $w > _last_week_number ($y) || $w == 0;
    my $day = ($w - 1) * 7 - _week_year_diff ($y);
    return $self->_set ($y, 1, 1, 0, 0, 0, '', undef, undef, $day * 24 * 3600 * 1000);
  } else {
    $self->onerror->(type => 'week:syntax error',
                     level => 'm');
    return $self->_reset;
  }
} # parse_week_string

sub to_week_string ($) {
  my $self = shift;
  return sprintf '%04d-W%02d', $self->utc_week_year, $self->utc_week;
} # to_week_string

sub parse_month_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4,})-([0-9]{2})\z/) {
    my ($y, $M) = ($1, $2);
    if ($y == 0) {
      $self->onerror->(type => 'datetime:bad year',
                       value => $y,
                       level => 'm');
      return $self->_reset;
    }

    if (0 < $M and $M < 13) {
      #
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return $self->_reset;
    }

    return $self->_set ($y, $M, 1, 0, 0, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'month:syntax error',
                     level => 'm');
    return $self->_reset;
  }
} # parse_month_string

sub to_month_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d', $self->utc_year, $self->utc_month;
} # to_month_string

sub parse_date_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4,})-([0-9]{2})-([0-9]{2})\z/x) {
    my ($y, $M, $d) = ($1, $2, $3);
    $self->onerror->(type => 'datetime:bad year',
                     year => $y,
                     level => 'm'), return $self->_reset if $y == 0;
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       year => $d,
                       level => 'm'), return $self->_reset
          if $d < 1 or
              $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return $self->_reset
          if $M == 2 and $d == 29 and
              not ($y % 400 == 0 or ($y % 4 == 0 and $y % 100 != 0));
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return $self->_reset;
    }
    return $self->_set ($y, $M, $d, 0, 0, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'date:syntax error',
                     level => 'm');
    return $self->_reset;
  }
} # parse_date_string

sub to_date_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02d',
      $self->utc_year, $self->utc_month, $self->utc_day;
} # to_date_string

sub parse_local_date_and_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ([0-9]{4,})-([0-9]{2})-([0-9]{2})
    [T\x20]
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)?
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf) = ($1, $2, $3, $4, $5, $6, $7);
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return $self->_reset if $y == 0;
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return $self->_reset
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return $self->_reset
          if $M == 2 and $d == 29 and not _is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return $self->_reset;
    }
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return $self->_reset if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return $self->_reset if $m > 59;
    $s ||= 0;
    $self->onerror->(type => 'datetime:bad second',
                     value => $d,
                     level => 'm'), return $self->_reset if $s > 59;
    $sf = defined $sf ? $sf : '';
    return $self->_set ($y, $M, $d, $h, $m, $s, $sf, undef, undef);
  } else {
    $self->onerror->(type => 'datetime-local:syntax error',
                     level => 'm');
    return $self->_reset;
  }
} # parse_local_date_and_time_string

sub to_local_date_and_time_string ($) {
  my $self = shift;
  return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s',
      $self->year, $self->month, $self->day,
      $self->hour, $self->minute, $self->second, $self->second_fraction_string;
} # to_local_date_and_time_string

sub parse_global_date_and_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ([0-9]{4,})-([0-9]{2})-([0-9]{2})
    [T\x20]
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)?
    (?>Z|([+-][0-9]{2}):([0-9]{2}))
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return $self->_reset
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return $self->_reset
          if $M == 2 and $d == 29 and not _is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return $self->_reset;
    }
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return $self->_reset if $y == 0;
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return $self->_reset if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return $self->_reset if $m > 59;
    $s ||= 0;
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return $self->_reset if $s > 59;
    $sf = defined $sf ? $sf : '';
    if (defined $zh) {
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return $self->_reset
          if $zh > 23 or $zh < -23;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return $self->_reset
          if $zm > 59;
    } else {
      $zh = 0;
      $zm = 0;
    }

    if ($zh eq '-00' and $zm eq '00') {
      $self->onerror->(type => 'datetime:-00:00',
                       level => 'm'); # don't return
      return $self->_set ($y, $M, $d, $h, $m, $s, $sf, undef, undef);
    } else {
      return $self->_set ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
    }
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return $self->_reset;
  }
} # parse_global_date_and_time_string

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

## Parse a date or time string
## <http://www.whatwg.org/specs/web-apps/current-work/#parse-a-date-or-time-string>
## but time-only string is not allowed
## <http://www.whatwg.org/specs/web-apps/current-work/#attr-mod-datetime>
sub parse_date_string_with_optional_time ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ([0-9]{4,})-([0-9]{2})-([0-9]{2})
    (?:[T\x20]
      ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)?
      (?>Z|([+-][0-9]{2}):([0-9]{2})))?
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return $self->_reset
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return $self->_reset
          if $M == 2 and $d == 29 and not _is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return $self->_reset;
    }
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return $self->_reset if $y == 0;
    
    if (defined $h) {
      $self->onerror->(type => 'datetime:bad hour',
                       value => $h,
                       level => 'm'), return $self->_reset if $h > 23;
      $self->onerror->(type => 'datetime:bad minute',
                       value => $m,
                       level => 'm'), return $self->_reset if $m > 59;
      $s ||= 0;
      $self->onerror->(type => 'datetime:bad second',
                       value => $s,
                       level => 'm'), return $self->_reset if $s > 59;
      $sf = defined $sf ? $sf : '';
      if (defined $zh) {
        $self->onerror->(type => 'datetime:bad timezone hour',
                         value => $zh,
                         level => 'm'), return $self->_reset
            if $zh > 23 or $zh < -23;
        $self->onerror->(type => 'datetime:bad timezone minute',
                         value => $zm,
                         level => 'm'), return $self->_reset
            if $zm > 59;
      } else {
        $zh = 0;
        $zm = 0;
      }
      if ($zh eq '-00' and $zm eq '00') {
        $self->onerror->(type => 'datetime:-00:00',
                         level => 'm'); # don't return
        return $self->_set ($y, $M, $d, $h, $m, $s, $sf, undef, undef);
      } else {
        return $self->_set ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
      }
    } else {
      ## A valid date string
      return $self->_set ($y, $M, $d, 0, 0, 0, 0, undef, undef);
    }
  } else {
    $self->onerror->(type => 'dateandopttime:syntax error',
                     level => 'm');
    return $self->_reset;
  }
} # parse_date_string_with_optional_time

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

  my $jan1 = __PACKAGE__->new->_set ($year, 1, 1, 0, 0, 0, 0, undef, undef);

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

sub _reset ($) {
  delete $_[0]->{$_} for qw(cache value timezone_hour timezone_minute
                            second_fraction);
  return $_[0];
} # _reset

my $unix_epoch = Time::Local::timegm (0, 0, 0, 1, 1 - 1, 1970);

sub _set ($$$$$$$$$$;$) {
  my $self = shift;
  my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm, $diff) = @_;
  
  delete $self->{cache};
  $self->{value} = Time::Local::timegm_nocheck
      ($s, $m - ($zm || 0), $h - ($zh|| 0), $d, $M-1, $y);
  if (defined $zh) {
    require Web::DateTime::TimeZone;
    $self->{tz} = Web::DateTime::TimeZone->new_from_offset
        ($zh * 60 * 60 + $zm * 60);
  } else {
    delete $self->{tz};
  }

  if ($self->year != $y or
      $self->month != $M or
      $self->day != $d or
      $self->hour != $h or
      $self->minute != $m) {
    ## Too large or small
    $self->onerror->(type => 'date value not supported',
                       value => join (", ", @_),
                       level => 'u');
    return $self->_reset;
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

sub has_value ($) {
  return defined $_[0]->{value};
} # has_value

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

# XXX to_time_piece

# XXX from_datetime
# XXX from_time_piece

# XXX normalized serializer
# XXX XML Schema datatypes
# XXX OGP datetime
# XXX RFC 3339 date-time
# XXX document.lastModified
# XXX HTTP datetime

# XXX JavaScript timestamp parser/serializer

1;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
