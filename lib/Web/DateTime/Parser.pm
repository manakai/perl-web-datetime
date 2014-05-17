package Web::DateTime::Parser;
use strict;
use warnings;
our $VERSION = '1.0';
use Web::DateTime;

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

## ------ Time ------

sub parse_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)?
  \z/x) {
    my ($h, $m, $s, $sf) = ($1, $2, $3, $4);
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return undef if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return undef if $m > 59;
    $s ||= 0;
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    $sf = defined $sf ? $sf : '';
    return $self->_create (1970, 1, 1, $h, $m, $s, $sf, undef, undef);
  } else {
    $self->onerror->(type => 'time:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_time_string

sub parse_xs_time_string ($$) {
  my ($self, $value) = @_;
  return $self->parse_xs_date_time_string ('1970-01-01T' . $value);
} # parse_xs_time_string

## ------ Week ------

sub parse_week_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4,})-W([0-9]{2})\z/x) {
    my ($y, $w) = ($1, $2);
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return undef if $y == 0;
    $self->onerror->(type => 'week:bad week',
                     value => $w,
                     level => 'm'), return undef
        if $w > Web::DateTime::_last_week_number ($y) || $w == 0;
    my $day = ($w - 1) * 7 - Web::DateTime::_week_year_diff ($y);
    return $self->_create ($y, 1, 1, 0, 0, 0, '', undef, undef, $day * 24 * 3600 * 1000);
  } else {
    $self->onerror->(type => 'week:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_week_string

## ------ Year ------

sub parse_year_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4,})\z/) {
    my ($y) = ($1);
    if ($y == 0) {
      $self->onerror->(type => 'datetime:bad year',
                       value => $y,
                       level => 'm');
      return undef;
    }

    return $self->_create ($y, 1, 1, 0, 0, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'year:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_year_string

sub parse_xs_g_year_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ s/^(-?[0-9]+)//) {
    return $self->parse_xs_date_time_string ($1 . '-01-01T00:00:00' . $value);
  } else {
    ## Syntax error
    return $self->parse_xs_date_time_string ($value . '-01-01T00:00:00');
  }
} # parse_xs_g_year_string

## ------ Month ------

sub parse_month_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4,})-([0-9]{2})\z/) {
    my ($y, $M) = ($1, $2);
    if ($y == 0) {
      $self->onerror->(type => 'datetime:bad year',
                       value => $y,
                       level => 'm');
      return undef;
    }

    if (0 < $M and $M < 13) {
      #
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }

    return $self->_create ($y, $M, 1, 0, 0, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'month:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_month_string

sub parse_xs_g_year_month_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ s/^(-?[0-9]+-[0-9]+)//) {
    return $self->parse_xs_date_time_string ($1 . '-01T00:00:00' . $value);
  } else {
    ## Syntax error
    return $self->parse_xs_date_time_string ($value . '-01T00:00:00');
  }
} # parse_xs_g_year_month_string

## ------ Date ------

sub parse_date_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4,})-([0-9]{2})-([0-9]{2})\z/x) {
    my ($y, $M, $d) = ($1, $2, $3);
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return undef if $y == 0;
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $d < 1 or
              $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $M == 2 and $d == 29 and
              not ($y % 400 == 0 or ($y % 4 == 0 and $y % 100 != 0));
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    return $self->_create ($y, $M, $d, 0, 0, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'date:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_date_string

sub parse_xs_date_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ s/^(-?[0-9]+-[0-9]+-[0-9]+)//) {
    return $self->parse_xs_date_time_string ($1 . 'T00:00:00' . $value);
  } else {
    ## Syntax error
    return $self->parse_xs_date_time_string ($value . 'T00:00:00');
  }
} # parse_xs_date_string

## ------ Yearless date ------

sub parse_yearless_date_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A(?:--|)([0-9]{2})-([0-9]{2})\z/x) {
    my ($M, $d) = ($1, $2);
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    return $self->_create (2000, $M, $d, 0, 0, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'date:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_yearless_date_string

sub parse_xs_g_month_day_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ s/^--([0-9]+-[0-9]+)//) {
    return $self->parse_xs_date_time_string ('2000-' . $1 . 'T00:00:00' . $value);
  } else {
    ## Syntax error
    return $self->parse_xs_date_time_string ('2000-' . $value . 'T00:00:00');
  }
} # parse_xs_g_month_day_string

## ------ Month only ------

sub parse_xs_g_month_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ s/^--([0-9]+)//) {
    return $self->parse_xs_date_time_string ('2000-' . $1 . '-01T00:00:00' . $value);
  } else {
    ## Syntax error
    return $self->parse_xs_date_time_string ('2000-' . $value . '-01T00:00:00');
  }
} # parse_xs_g_month_string

## ------ Day only ------

sub parse_xs_g_day_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ s/^---([0-9]+)//) {
    return $self->parse_xs_date_time_string ('2000-01-' . $1 . 'T00:00:00' . $value);
  } else {
    ## Syntax error
    return $self->parse_xs_date_time_string ('2000-01-' . $value . 'T00:00:00');
  }
} # parse_xs_g_day_string

## ------ Date and time ------

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
                     level => 'm'), return undef if $y == 0;
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $M == 2 and $d == 29 and not Web::DateTime::_is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return undef if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return undef if $m > 59;
    $s ||= 0;
    $self->onerror->(type => 'datetime:bad second',
                     value => $d,
                     level => 'm'), return undef if $s > 59;
    $sf = defined $sf ? $sf : '';
    return $self->_create ($y, $M, $d, $h, $m, $s, $sf, undef, undef);
  } else {
    $self->onerror->(type => 'datetime-local:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_local_date_and_time_string

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
                       level => 'm'), return undef
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $M == 2 and $d == 29 and not Web::DateTime::_is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return undef if $y == 0;
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return undef if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return undef if $m > 59;
    $s ||= 0;
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    $sf = defined $sf ? $sf : '';
    if (defined $zh) {
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return undef
          if $zh > 23 or $zh < -23;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return undef
          if $zm > 59;
    } else {
      $zh = 0;
      $zm = 0;
    }

    if ($zh eq '-00' and $zm eq '00') {
      $self->onerror->(type => 'datetime:-00:00',
                       level => 'm'); # don't return
      return $self->_create ($y, $M, $d, $h, $m, $s, $sf, undef, undef);
    } else {
      return $self->_create ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
    }
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_global_date_and_time_string

sub parse_xs_date_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    (-?[0-9]{4,})-([0-9]{2})-([0-9]{2})
    [T]
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)
    (Z|([+-][0-9]{2}):([0-9]{2}))?
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $has_zone, $zh, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
    $self->onerror->(type => 'datetime:negative year',
                     value => $y,
                     level => 'w')
        if $y <= 0;
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $M == 2 and $d == 29 and not Web::DateTime::_is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    $self->onerror->(type => 'datetime:year leading 0',
                     value => $y,
                     level => 'm')
        if $y =~ /^-?0[0-9]*[0-9]{4}$/;
    $s ||= 0;
    $sf = defined $sf ? $sf : '';
    if ($h == 24 and $m == 0 and $s == 0 and ($sf eq '' or $sf =~ /^\.0+$/)) {
      #
    } else {
      $self->onerror->(type => 'datetime:bad hour',
                       value => $h,
                       level => 'm'), return undef if $h > 23;
      $self->onerror->(type => 'datetime:bad minute',
                       value => $m,
                       level => 'm'), return undef if $m > 59;
      $self->onerror->(type => 'datetime:bad second',
                       value => $s,
                       level => 'm'), return undef if $s > 59;
    }
    if (not $has_zone) {
      #
    } elsif (defined $zh) {
      if (($zh == 14 or $zh == -14) and $zm == 0) {
        #
      } else {
        $self->onerror->(type => 'datetime:bad timezone hour',
                         value => $zh,
                         level => 'm'), return undef
            if $zh > 13 or $zh < -13;
        $self->onerror->(type => 'datetime:bad timezone minute',
                         value => $zm,
                         level => 'm'), return undef
            if $zm > 59;
      }
    } else {
      $zh = 0;
      $zm = 0;
    }
    return $self->_create ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_xs_date_time_string

sub parse_xs_date_time_stamp_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    (-?[0-9]{4,})-([0-9]{2})-([0-9]{2})
    [T]
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)
    (?>Z|([+-][0-9]{2}):([0-9]{2}))
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
    $self->onerror->(type => 'datetime:negative year',
                     value => $y,
                     level => 'w')
        if $y <= 0;
    if (0 < $M and $M < 13) {
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $M == 2 and $d == 29 and not Web::DateTime::_is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    $self->onerror->(type => 'datetime:year leading 0',
                     value => $y,
                     level => 'm')
        if $y =~ /^-?0[0-9]*[0-9]{4}$/;
    $s ||= 0;
    $sf = defined $sf ? $sf : '';
    if ($h == 24 and $m == 0 and $s == 0 and ($sf eq '' or $sf =~ /^\.0+$/)) {
      #
    } else {
      $self->onerror->(type => 'datetime:bad hour',
                       value => $h,
                       level => 'm'), return undef if $h > 23;
      $self->onerror->(type => 'datetime:bad minute',
                       value => $m,
                       level => 'm'), return undef if $m > 59;
      $self->onerror->(type => 'datetime:bad second',
                       value => $s,
                       level => 'm'), return undef if $s > 59;
    }
    if (defined $zh) {
      if (($zh == 14 or $zh == -14) and $zm == 0) {
        #
      } else {
        $self->onerror->(type => 'datetime:bad timezone hour',
                         value => $zh,
                         level => 'm'), return undef
            if $zh > 13 or $zh < -13;
        $self->onerror->(type => 'datetime:bad timezone minute',
                         value => $zm,
                         level => 'm'), return undef
            if $zm > 59;
      }
    } else {
      $zh = 0;
      $zm = 0;
    }
    return $self->_create ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_xs_date_time_stamp_string

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
                       level => 'm'), return undef
          if $d < 1 or
             $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$M];
      $self->onerror->(type => 'datetime:bad day',
                       value => $d,
                       level => 'm'), return undef
          if $M == 2 and $d == 29 and not Web::DateTime::_is_leap_year ($y);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    $self->onerror->(type => 'datetime:bad year',
                     value => $y,
                     level => 'm'), return undef if $y == 0;
    
    if (defined $h) {
      $self->onerror->(type => 'datetime:bad hour',
                       value => $h,
                       level => 'm'), return undef if $h > 23;
      $self->onerror->(type => 'datetime:bad minute',
                       value => $m,
                       level => 'm'), return undef if $m > 59;
      $s ||= 0;
      $self->onerror->(type => 'datetime:bad second',
                       value => $s,
                       level => 'm'), return undef if $s > 59;
      $sf = defined $sf ? $sf : '';
      if (defined $zh) {
        $self->onerror->(type => 'datetime:bad timezone hour',
                         value => $zh,
                         level => 'm'), return undef
            if $zh > 23 or $zh < -23;
        $self->onerror->(type => 'datetime:bad timezone minute',
                         value => $zm,
                         level => 'm'), return undef
            if $zm > 59;
      } else {
        $zh = 0;
        $zm = 0;
      }
      if ($zh eq '-00' and $zm eq '00') {
        $self->onerror->(type => 'datetime:-00:00',
                         level => 'm'); # don't return
        return $self->_create ($y, $M, $d, $h, $m, $s, $sf, undef, undef);
      } else {
        return $self->_create ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
      }
    } else {
      ## A valid date string
      return $self->_create ($y, $M, $d, 0, 0, 0, 0, undef, undef);
    }
  } else {
    $self->onerror->(type => 'dateandopttime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_date_string_with_optional_time

sub parse_date_string_with_optional_time_and_duration ($$) {
  my ($self, $value) = @_;
  my ($v1, $v2) = split m{/}, $value, 2;
  if (defined $v2) {
    my $dt1 = $self->parse_global_date_and_time_string ($v1) or return undef;
    if ($v2 =~ /^[0-9]+-/) {
      my $dt2 = $self->parse_global_date_and_time_string ($v2) or return undef;
      if ($dt1->to_unix_number <= $dt2->to_unix_number) {
        require Web::DateTime::Interval;
        return Web::DateTime::Interval->new_from_date_times ($dt1, $dt2);
      } else {
        $self->onerror->(type => 'interval:not 1<=2',
                         level => 'm');
        return undef;
      }
    } else {
      my $duration = $self->parse_vevent_duration_string ($v2) or return undef;
      require Web::DateTime::Interval;
      return Web::DateTime::Interval->new_from_date_time_and_duration
          ($dt1, $duration);
    }
  } else {
    return $self->parse_date_string_with_optional_time ($v1);
  }
} # parse_date_string_with_optional_time_and_duration

## ------ Time zone ------

sub parse_time_zone_offset_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A(?:
    Z
    |
    ([+-])([0-9]{2}):([0-9]{2})
  )\z/x) {
    my ($zs, $zh, $zm) = ($1, $2, $3);
    if (defined $zh) {
      $zs .= '1';
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return undef
          if $zh > 23;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return undef
          if $zm > 59;
    } else { ## Z
      $zs = +1;
      $zh = 0;
      $zm = 0;
    }
    if ($zs == -1 and $zh == 0 and $zm == 0) {
      $self->onerror->(type => 'datetime:-00:00',
                       level => 'm'); # don't return
    }
    require Web::DateTime::TimeZone;
    return Web::DateTime::TimeZone->new_from_offset ($zs * ($zh * 60 * 60 + $zm * 60));
  } else {
    $self->onerror->(type => 'tz:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_time_zone_offset_string

sub _create {
  my ($self, $y, $M, $d, $h, $m, $s, $sf, $zh, $zm, $diff) = @_;
  my $dt = Web::DateTime->_create ($y, $M, $d, $h, $m, $s, $sf, $zh, $zm, $diff);

  unless ($diff) { # XXX
  unless ($h == 24) { # XXX
  if ($dt->year != $y and not ($dt->year + 1 == $y or $dt->year - 1 == $y) #or
      #$dt->month != $M or
      #$dt->day != $d or
      #$dt->hour != $h or
      #$dt->minute != $m
  ) {
    ## Too large or small
    #warn $dt->to_global_date_and_time_string;
    $self->onerror->(type => 'date value not supported',
                     value => join (", ", map { defined $_ ? $_ : '' } $y, $M, $d, $h, $m, $s, $sf, $zh, $zm, $diff, $dt->to_global_date_and_time_string),
                     level => 'u');
    # XXX 0001-0999
    return undef;
  }}}

  return $dt;
} # _create

# XXX parser for HTML <time> value

## ------ Duration ------

my $DurationScale = {
  W => 604800,
  w => 604800,
  D => 86400,
  d => 86400,
  H => 3600,
  h => 3600,
  M => 60,
  m => 60,
  S => 1,
  s => 1,
};

sub parse_duration_string ($$) {
  return shift->_parse_duration
      ($_[0],
       allow_html_duration => 1,
       allow_second_fraction => 1,
       allow_hs => 1);
} # parse_duration_string

sub parse_vevent_duration_string ($$) {
  return shift->_parse_duration ($_[0], allow_w => 1);
} # parse_vevent_duration_string

sub parse_xs_duration_string ($$) {
  return shift->_parse_duration
      ($_[0],
       allow_negative => 1,
       allow_months => 1,
       allow_second_fraction => 1,
       allow_hs => 1);
} # parse_xs_duration_string

sub parse_xs_day_time_duration_string ($$) {
  return shift->_parse_duration
      ($_[0],
       allow_negative => 1,
       allow_months => 0,
       allow_second_fraction => 1,
       allow_hs => 1);
} # parse_xs_day_time_duration_string

sub parse_xs_year_month_duration_string ($$) {
  return shift->_parse_duration
      ($_[0],
       allow_negative => 1,
       allow_months => 1,
       disallow_seconds => 1,
       allow_second_fraction => 1,
       allow_hs => 1);
} # parse_xs_year_month_duration_string

sub _parse_duration ($$%) {
  my ($self, $value, %args) = @_;
  my $sign = +1;
  if ($args{allow_negative} and $value =~ s/^-//) {
    $sign = -1;
  }
  if ($value =~ m{\A
    [\x09\x0A\x0C\x0D\x20]*
    P?
    (?:
      T [\x09\x0A\x0C\x0D\x20]*
        |
      [0-9]+ [\x09\x0A\x0C\x0D\x20]* [YyWwDdHhMmSs] [\x09\x0A\x0C\x0D\x20]*
        |
      [0-9]+\.[0-9]+ [\x09\x0A\x0C\x0D\x20]* [Ss] [\x09\x0A\x0C\x0D\x20]*
        |
      \.[0-9]+ [\x09\x0A\x0C\x0D\x20]* [Ss] [\x09\x0A\x0C\x0D\x20]*
    )+
  \z}x) {
    if ($value =~ tr/\x09\x0A\x0C\x0D\x20//d) {
      if ($value =~ /[PT]/) {
        $self->onerror->(type => 'duration:space',
                         level => 'm');
      }
    }
    my $seconds = 0;
    my $months = 0;
    my $m = 'minute';
    my $suffix = '';
    for (grep { length } split /([0-9.]+[A-Za-z]|[PT])/, $value) {
      if (/\A([0-9]+)[Mm]\z/) {
        if ($m eq 'minute') {
          $seconds += $1 * $DurationScale->{M};
        } else {
          $months += $1;
        }
      } elsif (/\A([0-9]+)[Yy]\z/) {
        $months += $1 * 12;
      } elsif (/\A([0-9.]+)([A-Za-z])\z/) {
        $seconds += $1 * $DurationScale->{$2};
      }

      if (/([A-Za-z])\z/) {
        $suffix .= $1;
      }
      
      if ($_ eq 'P' or /[Yy]\z/) {
        $m = 'month';
      } elsif (/[Mm]\z/) {
        #
      } else {
        $m = 'minute';
      }
    }
    if (not $args{allow_second_fraction} and
        $value =~ /[.][0-9]+[Ss]/) {
      $self->onerror->(type => 'datetime:fractional second',
                       level => 'm');
    }

    if ($value =~ /[PT]/) {
      if ($value =~ /T/ and not $value =~ /P/) {
        $self->onerror->(type => 'duration:syntax error',
                         value => $suffix,
                         level => 'm');
      } else {
        if ($suffix =~ /([a-z])/) {
          $self->onerror->(type => 'duration:case',
                           value => $1,
                           level => 'm');
          $suffix = uc $suffix;
        }
        if ($args{allow_w} and $suffix =~ /\APW\z/) {
          #
        } elsif ($suffix =~ /\AP?Y?M?(?:D|TH?M?S?|DTH?M?S?)\z/ and
                 not $args{disallow_seconds}) {
          if ($suffix =~ /T/) {
            if ($suffix =~ /THS/) {
              if ($args{allow_hs}) {
                #
              } else {
                $self->onerror->(type => 'duration:syntax error',
                                 value => $suffix,
                                 level => 'm');
              }
            } elsif ($suffix =~ /THM?S?|TH?MS?|TH?M?S/) {
              #
            } else {
              $self->onerror->(type => 'duration:syntax error',
                               value => $suffix,
                               level => 'm');
            }
          }
        } elsif ($args{allow_months} and $suffix =~ /\AP(?:YM?D?|MD?|D)\z/) {
          #
        } else {
          $self->onerror->(type => 'duration:syntax error',
                           value => $suffix,
                           level => 'm');
        }
      }
    } else {
      if (not $args{allow_html_duration}) {
        $self->onerror->(type => 'duration:html duration',
                         level => 'm');
      } elsif ($suffix =~ /[Yy]/) {
        $self->onerror->(type => 'duration:syntax error',
                         value => $suffix,
                         level => 'm');
      }
    }

    if ($months) {
      if ($args{allow_months}) {
        #
      } else {
        $self->onerror->(type => 'duration:months',
                         level => 'm');
        return undef;
      }
    }
    require Web::DateTime::Duration;
    return Web::DateTime::Duration->new_from_seconds_and_months_and_sign
        ($seconds, $months, $sign);
  } else {
    $self->onerror->(type => 'duration:syntax error',
                     level => 'm');
    return undef;
  }
} # _parse_duration

1;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
