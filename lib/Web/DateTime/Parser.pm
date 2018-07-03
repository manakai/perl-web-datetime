package Web::DateTime::Parser;
use strict;
use warnings;
no warnings 'utf8';
our $VERSION = '2.0';
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
    return $self->_create
        ({time => 1}, 1970, 1, 1, $h, $m, $s, $sf, undef, undef);
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
    return $self->_create
        ({year => 1, week => 1},
         $y, 1, 1, 0, 0, 0, '', undef, undef, $day * 24 * 3600 * 1000);
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

    return $self->_create ({year => 1}, $y, 1, 1, 0, 0, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'year:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_year_string

sub parse_manakai_year_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([+-]?[0-9]+)\z/) {
    my ($y) = (0+$1);
    return $self->_create ({year => 1}, $y, 1, 1, 0, 0, 0, '', 0, 0);
  } else {
    $self->onerror->(type => 'year:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_manakai_year_string

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

    return $self->_create ({year => 1, month => 1},
                           $y, $M, 1, 0, 0, 0, '', undef, undef);
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
    return $self->_create ({year => 1, month => 1, day => 1},
                           $y, $M, $d, 0, 0, 0, '', undef, undef);
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

sub parse_iso8601_date_string ($$) {
  my ($self, $value) = @_;

  if ($value =~ /\x{2010}/) {
    $self->onerror->(type => 'datetime:hyphen',
                     level => 'w');
  }
  if ($value =~ /\x{2212}/) {
    $self->onerror->(type => 'datetime:minus sign',
                     level => 'w');
  }
  if ($value =~ /w/) {
    $self->onerror->(type => 'datetime:lowercase designator',
                     value => 'w',
                     level => 'w');
  }

  my $y;
  my $M;
  my $w;
  my $d;

  if ($value =~ /\A([0-9]{4}|[+-][0-9]{4,})[-\x{2010}]([0-9]{2})[-\x{2010}]([0-9]{2})\z/) {
    $y = $1;
    $M = $2;
    $d = $3;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})[-\x{2010}]([0-9]{3})\z/) {
    $y = $1;
    $d = $2;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})[-\x{2010}][Ww]([0-9]{2})[-\x{2010}]([0-9])\z/) {
    $y = $1;
    $w = $2;
    $d = $3;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})[-\x{2010}]([0-9]{2})\z/) {
    $y = $1;
    $M = $2;
    $d = 1;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})[-\x{2010}][Ww]([0-9]{2})\z/) {
    $y = $1;
    $w = $2;
    $d = 1;
  } elsif ($value =~ /\A([0-9]{4}|[+-][0-9]{4,})([0-9]{2})([0-9]{2})\z/) {
    $y = $1;
    $M = $2;
    $d = $3;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})([0-9]{3})\z/) {
    $y = $1;
    $d = $2;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})[Ww]([0-9]{2})([0-9])\z/) {
    $y = $1;
    $w = $2;
    $d = $3;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})([0-9]{2})\z/) {
    $y = $1;
    $M = $2;
    $d = 1;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})[Ww]([0-9]{2})\z/) {
    $y = $1;
    $w = $2;
    $d = 1;
  } elsif ($value =~ /\A([0-9]{4}|[+\x{2212}-][0-9]{4,})\z/) {
    $y = $1;
    $M = 1;
    $d = 1;
  } elsif ($value =~ /\A([0-9]{2}|[+\x{2212}-][0-9]{2,})\z/) {
    $y = $1 . '00';
    $M = 1;
    $d = 1;
  } else {
    $self->onerror->(type => 'date:syntax error',
                     level => 'm');
    return undef;
  }

  $y =~ s/\x{2212}/-/g;
  if ($y =~ /^[+-]/) {
    $self->onerror->(type => 'datetime:expanded year',
                     value => $y,
                     level => 'w');
  }
  if ($y <= 1582) {
    $self->onerror->(type => 'datetime:pre-gregorio year',
                     value => $y,
                     level => 'w');
  }

  if (defined $w) { ## Y, W, D
    $self->onerror->(type => 'week:bad week',
                     value => $w,
                     level => 'm'), return undef
        if $w > Web::DateTime::_last_week_number ($y) || $w == 0;
    $self->onerror->(type => 'datetime:bad day',
                     value => $d,
                     level => 'm'), return undef
        if $d < 1 or $d > 7;
    my $day = ($w - 1) * 7 - Web::DateTime::_week_year_diff ($y);
    $day += $d - 1;
    return $self->_create
        ({year => 1, week => 1, day => 1},
         $y, 1, 1, 0, 0, 0, '', undef, undef, $day * 24 * 3600 * 1000);
  } elsif (not defined $M) { ## Y, D
    $self->onerror->(type => 'datetime:bad day',
                     value => $d,
                     level => 'm'), return undef
        if $d < 1 or $d > 366 or
           ($d == 366 and not Web::DateTime::_is_leap_year ($y));
    return $self->_create
        ({year => 1, day => 1},
         $y, 1, 1, 0, 0, 0, '', undef, undef, ($d - 1) * 24 * 3600 * 1000);
  } else { ## Y, M, D
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
      return $self->_create
          ({year => 1, month => 1, day => 1},
           $y, $M, $d, 0, 0, 0, '', undef, undef);
    } else {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
  }
} # parse_iso8601_date_string

sub parse_ymd_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([+-]?[0-9]+)-([0-9]+)-([0-9]+)\z/) {
    my ($y, $m, $d) = (0+$1, 0+$2, 0+$3);
    return $self->_create ({year => 1, month => 1, day => 1},
                           $y, $m, $d, 0, 0, 0, '', 0, 0);
  } else {
    $self->onerror->(type => 'date:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_ymd_string

sub parse_julian_ymd_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([+-]?[0-9]+)-([0-9]+)-([0-9]+)\z/) {
    my ($y, $m, $d) = (0+$1, 0+$2, 0+$3);
    return $self->_create ({year => 1, month => 1, day => 1},
                           $y, $m, $d, 0, 0, 0, '', 0, 0, undef, 'julian');
  } else {
    $self->onerror->(type => 'date:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_julian_ymd_string

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
    return $self->_create
        ({month => 1, day => 1},
         2000, $M, $d, 0, 0, 0, '', undef, undef);
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
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    $sf = defined $sf ? $sf : '';
    return $self->_create
        ({year => 1, month => 1, day => 1, time => 1},
         $y, $M, $d, $h, $m, $s, $sf, undef, undef);
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
    (?>Z|([+-][0-9]{2})(:?)([0-9]{2}))
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zc, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
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
      $self->onerror->(type => 'tz:syntax error',
                       level => 'm') # no return
          if not $zc;
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
    }
    return $self->_create
        ({year => 1, month => 1, day => 1, time => 1, offset => 1},
         $y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_global_date_and_time_string

sub parse_rfc3339_date_time_string ($$) {
  my ($self, $value) = @_;
  $self->_parse_rfc3339_date_time_string ($value);
} # parse_rfc3339_date_time_string

sub parse_rfc3339_xs_date_time_string ($$) {
  my ($self, $value) = @_;
  return $self->_parse_rfc3339_date_time_string
      ($value,
       lowercase_level => 'm',
       xs_tz_range => 1,
       disallow_leap_second => 1,
       max_zh => 13);
} # parse_rfc3339_xs_date_time_string

sub _parse_rfc3339_date_time_string ($$;%) {
  my ($self, $value, %args) = @_;

  if ($value =~ s/([a-z])/uc $1/ge) {
    $self->onerror->(type => 'datetime:lowercase designator',
                     value => $1,
                     level => $args{lowercase_level} || 's');
  }

  if ($value =~ /\A
    ([0-9]{4})-([0-9]{2})-([0-9]{2})
    [T]
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)
    (?>[Z]|([+-][0-9]{2})(:?)([0-9]{2}))
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zc, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
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
    my $leap_second;
    if (not $args{disallow_leap_second} and $s == 60) {
      $leap_second = 1;
      $s--;
    }
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    $sf = defined $sf ? $sf : '';
    if (defined $zh) {
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return undef
          if $zh > +23 or $zh < -23;
      if (($zh == 14 or $zh == -14) and $zm == 0) {
        #
      } elsif (defined $args{max_zh}) {
        $self->onerror->(type => 'datetime:bad timezone hour',
                         value => $zh,
                         level => 'm')
            if $zh > +$args{max_zh} or $zh < -$args{max_zh};
      }
      $self->onerror->(type => 'tz:syntax error',
                       level => 'm') # no return
          if not $zc;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return undef
          if $zm > 59;
    } else {
      $zh = 0;
      $zm = 0;
    }

    if ($zh eq '-00' and $zm eq '00') {
      undef $zh;
      undef $zm;
    }
    my $dt = $self->_create
        ({year => 1, month => 1, day => 1, time => 1, offset => defined $zh},
         $y, $M, $d, $h, $m, $s, $sf, $zh, $zm)
        or return undef;

    if ($leap_second) {
      require Web::DateTime::_Defs;
      my $time = $dt->to_unix_integer;
      if ($Web::DateTime::_Defs->{positive_leap_second_after}->{$time}) {
        return $dt;
      } elsif (not defined $zh) {
        for (keys %{$Web::DateTime::_Defs->{positive_leap_second_after}}) {
          if ($time - 24*60*60 < $_ and $_ < $time + 24*60*60) {
            return $dt;
          }
        }
      }
      $self->onerror->(type => 'datetime:bad second',
                       value => '60',
                       level => 'm');
      return undef;
    } # $leap_secnd

    return $dt;
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # _parse_rfc3339_date_time_string

sub parse_xs_date_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    (-?[0-9]{4,})-([0-9]{2})-([0-9]{2})
    [T]
    ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)
    (Z|([+-][0-9]{2})(:?)([0-9]{2}))?
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $has_zone, $zh, $zc, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
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
        $self->onerror->(type => 'tz:syntax error',
                         level => 'm') # no return
            if not $zc;
        $self->onerror->(type => 'datetime:bad timezone minute',
                         value => $zm,
                         level => 'm'), return undef
            if $zm > 59;
      }
    } else {
      $zh = 0;
      $zm = 0;
    }
    return $self->_create
        ({type => 1, month => 1, day => 1, time => 1, offset => $has_zone},
         $y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
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
    (?>Z|([+-][0-9]{2})(:?)([0-9]{2}))
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zc, $zm)
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
    if (defined $zh) {
      if (($zh == 14 or $zh == -14) and $zm == 0) {
        #
      } else {
        $self->onerror->(type => 'datetime:bad timezone hour',
                         value => $zh,
                         level => 'm'), return undef
            if $zh > 13 or $zh < -13;
        $self->onerror->(type => 'tz:syntax error',
                         level => 'm') # no return
            if not $zc;
        $self->onerror->(type => 'datetime:bad timezone minute',
                         value => $zm,
                         level => 'm'), return undef
            if $zm > 59;
      }
    } else {
      $zh = 0;
      $zm = 0;
    }
    return $self->_create
        ({year => 1, month => 1, day => 1, time => 1, offset => 1},
         $y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_xs_date_time_stamp_string

sub parse_schema_org_date_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    (-?[0-9]{4})-([0-9]{2})-([0-9]{2})
    T
    ([0-9]{2}):([0-9]{2}):([0-9]{2})
    (
      Z |
      ([+-][0-9]{2})(:?)([0-9]{2})
    )?
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $z, $zh, $zc, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
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
    if ($y =~ /^[+-]/) {
      $self->onerror->(type => 'datetime:expanded year',
                       value => $y,
                       level => 'w');
    }
    if ($y <= 1582) {
      $self->onerror->(type => 'datetime:pre-gregorio year',
                       value => $y,
                       level => 'w');
    }
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return undef if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return undef if $m > 59;
    my $leap_second;
    if ($s == 60) {
      $s--;
      $leap_second = 1;
    }
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    if (not defined $z) {
      #
    } elsif (defined $zh) {
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return undef
          if $zh > +24 or $zh < -24;
      $self->onerror->(type => 'tz:syntax error',
                       level => 'm') # no return
          if not $zc;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return undef
          if $zm > 59 or (($zh == +24 or $zh == -24) and $zm != 0);
    } else {
      $zh = 0;
      $zm = 0;
    }

    if (defined $zh and $zh eq '-00' and $zm eq '00') {
      $self->onerror->(type => 'datetime:-00:00',
                       level => 'm'); # don't return
    }
    my $dt = $self->_create
        ({year => 1, month => 1, day => 1, time => 1, offset => defined $z},
         $y, $M, $d, $h, $m, $s, '', $zh, $zm);
    if ($leap_second) {
      require Web::DateTime::_Defs;
      my $time = $dt->to_unix_integer;
      if ($Web::DateTime::_Defs->{positive_leap_second_after}->{$time}) {
        return $dt;
      } elsif (not defined $zh) {
        for (keys %{$Web::DateTime::_Defs->{positive_leap_second_after}}) {
          if ($time - 24*60*60 < $_ and $_ < $time + 24*60*60) {
            return $dt;
          }
        }
      }
      $self->onerror->(type => 'datetime:bad second',
                       value => '60',
                       level => 'm');
      return undef;
    } # $leap_secnd

    return $dt;
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_schema_org_date_time_string

sub parse_pkix_generalized_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})Z\z/) {
    my ($y, $M, $d, $h, $m, $s) = ($1, $2, $3, $4, $5, $6);
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
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    return $self->_create
        ({type => 1, month => 1, day => 1, time => 1, offset => 1},
         $y, $M, $d, $h, $m, $s, '', 0, 0);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_pkix_generalized_time_string

## RFC 6265 Section 5.1.1. with a bug fix: "(non-digit *OCTET)" in
## grammer can be omitted.
sub parse_http_date_string ($$) {
  my ($self, $value) = @_;

  unless ($value =~ /\A
    (?:[Mm][Oo][Nn]|[Tt][Uu][Ee]|[Ww][Ee][Dd]|
       [Tt][Hh][Uu]|[Ff][Rr][Ii]|[Ss][Aa][Tt]|[Ss][Uu][Nn])
    ,\x20
    [0-9]{2}
    \x20
    [A-Za-z]+
    \x20
    [0-9]{4}
    \x20
    [0-9]{2}:[0-9]{2}:[0-9]{2}
    \x20
    [Gg][Mm][Tt]
  \z/x) {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
  }
  my $dow;
  $dow = $1
      if $value =~ /\A(
          [Mm][Oo][Nn]|[Tt][Uu][Ee]|[Ww][Ee][Dd]|
          [Tt][Hh][Uu]|[Ff][Rr][Ii]|[Ss][Aa][Tt]|[Ss][Uu][Nn]
      )/x;

  ## Step 1.
  my @token = split /([\x09\x20-\x2F\x3B-\x40\x5B-\x60\x7B-\x7E])/, $value, -1;
  
  ## Step 2.
  my $hour_value;
  my $minute_value;
  my $second_value;
  my $day_of_month_value;
  my $month_value;
  my $year_value;
  for my $token (@token) {
    ## Step 2.1.
    if (not defined $hour_value and
        $token =~ /\A([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})(?:[^0-9].*|)\z/s) {
      $hour_value = $1;
      $minute_value = $2;
      $second_value = $3;
      next;
    }

    ## Step 2.2.
    if (not defined $day_of_month_value and 
        $token =~ /\A([0-9]{1,2})(?:[^0-9].*|)\z/s) {
      $day_of_month_value = $1;
      next;
    }
    
    ## Step 2.3.
    if (not defined $month_value and
        $token =~ /\A([Jj][Aa][Nn]|[Ff][Ee][Bb]|[Mm][Aa][Rr]|[Aa][Pp][Rr]|[Mm][Aa][Yy]|[Jj][Uu][Nn]|[Jj][Uu][Ll]|[Aa][Uu][Gg]|[Ss][Ee][Pp]|[Oo][Cc][Tt]|[Nn][Oo][Vv]|[Dd][Ee][Cc])(.*)\z/s) {
      $month_value = {qw(jan 1 feb 2 mar 3 apr 4 may 5 jun 6 jul 7
                         aug 8 sep 9 oct 10 nov 11 dec 12)}->{lc $1};
      if (length $2) {
        $self->onerror->(type => 'datetime:bad month',
                         value => $token,
                         level => 'm');
      }
      next;
    }

    if (not defined $year_value and
        $token =~ /\A([0-9]{2,4})(?:[^0-9].*|)\z/s) {
      $year_value = $1;
      next;
    }
  } # @token

  ## Step 5.
  return undef if 
      not defined $day_of_month_value or
      not defined $month_value or
      not defined $year_value or
      not defined $hour_value;

  ## Step 3.
  if ($year_value >= 70 and $year_value <= 99) {
    $year_value += 1900;
  }

  ## Step 4.
  if ($year_value >= 0 and $year_value <= 69) {
    $year_value += 2000;
  }

  ## Step 5.
  if ($year_value < 1601) {
    $self->onerror->(type => 'datetime:bad year',
                     value => $year_value,
                     level => 'w');
    return undef;
  }
  if ($hour_value > 23) {
    $self->onerror->(type => 'datetime:bad hour',
                     value => $hour_value,
                     level => 'm');
    return undef;
  }
  if ($minute_value > 59) {
    $self->onerror->(type => 'datetime:bad minute',
                     value => $minute_value,
                     level => 'm');
    return undef;
  }
  if ($second_value > 59) {
    $self->onerror->(type => 'datetime:bad second',
                     value => $second_value,
                     level => 'm');
    return undef;
  }

  ## Step 6., Step 7.
  $self->onerror->(type => 'datetime:bad day',
                   value => $day_of_month_value,
                   level => 'm'), return undef
      if $day_of_month_value < 1 or
         $day_of_month_value > [0,
                                31, 29, 31, 30, 31, 30,
                                31, 31, 30, 31, 30, 31]->[$month_value];
  $self->onerror->(type => 'datetime:bad day',
                   value => $day_of_month_value,
                   level => 'm'), return undef
    if $month_value == 2 and $day_of_month_value == 29 and
       not Web::DateTime::_is_leap_year ($year_value);
  my $dt = $self->_create
      ({year => 1, month => 1, day => 1, time => 1, zone => 1},
       $year_value, $month_value, $day_of_month_value,
       $hour_value, $minute_value, $second_value, '', 0, 0)
      or return undef;
  if (defined $dow) {
    my $dow_n = {sun => 0, mon => 1, tue => 2, wed => 3,
                 thu => 4, fri => 5, sat => 6}->{lc $dow};
    unless ($dt->day_of_week == $dow_n) {
      $self->onerror->(type => 'datetime:bad weekday',
                       text => [qw[Sun Mon Tue Wed Thu Fri Sat]]->[$dt->day_of_week],
                       value => $dow,
                       level => 'm');
    }
  }
  return $dt;
} # parse_http_date_string

our $CContent; $CContent = qr/(?>[^()\\]+|\\.|\((??{ $CContent})\))*/;
my $CFWS = qr/(?>[\x09\x0A\x0D\x20]+|\($CContent\))/s;

sub parse_rss2_date_time_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ($CFWS*)
    (?:
      ([A-Za-z]+) ($CFWS*) , ($CFWS*)
    )?

    ([0-9]+) ($CFWS+)
    ([A-Za-z]+) ($CFWS+)
    ([0-9]+) ($CFWS+)

    ([0-9]+) ($CFWS*)
    : ($CFWS*)
    ([0-9]+) ($CFWS*)
    (?:
      : ($CFWS*)
      ([0-9]+) ($CFWS+)
    )?

    (
      [A-Za-z]+ |
      [+-][0-9]{4}
    )

    ($CFWS*)
  \z/xo) {
    my ($s1, $wd, $s2, $s3, $d, $s4, $M, $s5, $y, $s6,
        $h, $s7, $s8, $m, $s9, $s10, $s, $s11, $z, $s12)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
           $11, $12, $13, $14, $15, $16, $17, $18, $19, $20);

    my $month = {qw(jan 1 feb 2 mar 3 apr 4 may 5 jun 6 jul 7
                    aug 8 sep 9 oct 10 nov 11 dec 12)}->{lc $M};
    unless (defined $month) {
      $self->onerror->(type => 'datetime:bad month',
                       value => $M,
                       level => 'm');
      return undef;
    }
    if ($M ne ucfirst lc $M) {
      $self->onerror->(type => 'datetime:month:bad case',
                       value => $M,
                       level => 's');
    }

    if (2 == length $y) {
      $self->onerror->(type => 'datetime:bad year',
                       value => $y,
                       level => 's');
      ## RFC 2822 interpretation
      $y = $y + 1900;
      $y += 100 if $y < 1950;
    } elsif (3 == length $y) {
      $self->onerror->(type => 'datetime:bad year',
                       value => $y,
                       level => 'm');
      $y += 1900; ## RFC 2822 interpretation
    } elsif (not 4 == length $y) {
      $self->onerror->(type => 'datetime:bad year',
                       value => $y,
                       level => 'm');
    }

    $self->onerror->(type => 'datetime:bad day',
                     value => $d,
                     level => 'm'), return undef
        if $d < 1 or
           $d > [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]->[$month];
    $self->onerror->(type => 'datetime:bad day',
                     value => $d,
                     level => 'm'), return undef
        if $month == 2 and $d == 29 and
           not Web::DateTime::_is_leap_year ($y);
    $self->onerror->(type => 'datetime:bad day',
                     value => $d,
                     level => 'm')
        unless 2 >= length $d;

    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return undef if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return undef if $m > 59;
    $s ||= '00';
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    if (2 != length $h or
        2 != length $m or
        2 != length $s) {
      $self->onerror->(type => 'datetime:syntax error',
                       level => 'm');
      # not return
    }

    my ($zh, $zm);
    if ($z =~ /\A([+-])([0-9][0-9])([0-9][0-9])\z/) {
      $zh = $1.$2;
      $zm = $3;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return undef
          if $zm > 59;
    } else {
      require Web::DateTime::_Defs;
      my $def = $Web::DateTime::_Defs->{mail_tz_names}->{uc $z} || {};
      if (defined $def->{offset} and
          not $def->{offset_unknown} and
          not $def->{offset} % 60) {
        $zh = int ($def->{offset} / 60 / 60);
        $zm = ($def->{offset} / 60) % 60;
      }

      if ($def->{allowed_rfc822}) {
        if ($def->{allowed_but_not_recommended}) {
          $self->onerror->(type => 'datetime:tzname',
                           value => $z,
                           level => 's');
        } elsif ('GMT' eq uc $z) {
          #
        } else {
          $self->onerror->(type => 'datetime:tzname',
                           value => $z,
                           level => 'w');
        }
      } else {
        $self->onerror->(type => 'datetime:tzname',
                         value => $z,
                         level => 'm');
      }
      if ($z ne uc $z) {
        $self->onerror->(type => 'datetime:tz:bad case',
                         value => $z,
                         level => 's');
      }
    } # zone

    for ($s1, $s2, $s3, $s4, $s5, $s6, $s7, $s8, $s9, $s10, $s11, $s12) {
      next if not defined $_ or $_ eq '' or $_ eq ' ';
      if (/[^\x00-\x7F]/ or /\x0D\x0A(?![\x20\x09])/) {
        $self->onerror->(type => 'datetime:syntax error',
                         value => $_,
                         level => 'm');
      } else {
        $self->onerror->(type => 'datetime:bad CFWS',
                         value => $_,
                         level => 's');
      }
    }


    my $dt = $self->_create
        ({year => 1, month => 1, day => 1, time => 1, offset => defined $zh},
         $y, $month, $d, $h, $m, $s, '', $zh, $zm)
        or return undef;
    if (defined $wd) {
      my $dow_n = {sun => 0, mon => 1, tue => 2, wed => 3,
                   thu => 4, fri => 5, sat => 6}->{lc $wd};
      if (not defined $dow_n or not $dt->day_of_week == $dow_n) {
        $self->onerror->(type => 'datetime:bad weekday',
                         text => [qw[Sun Mon Tue Wed Thu Fri Sat]]->[$dt->day_of_week],
                         value => $wd,
                         level => 'm');
      }
      if ($wd ne ucfirst lc $wd) {
        $self->onerror->(type => 'datetime:weekday:bad case',
                         value => $wd,
                         level => 's');
      }
    }
    return $dt;
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_rss2_date_time_string

sub parse_js_date_time_string ($$) {
  my ($self, $value) = @_;
  ## This method does not detect all conformance errors for now.  In
  ## fact there is no actual spec...
  if ($value =~ m{\A
    ## ECMA-262's profile of ISO 8601, with extensions
    ([+-]?[0-9]{1,}) # [0-9]{4}|[+-][0-9]{6} in ECMA-262
    (?:
      [-/] ([0-9]{1,}) # [0-9]{2} in ECMA-262
      (?:
        [-/] ([0-9]{1,}) # [0-9]{2} in ECMA-262
      )?
    )? # separators are - in ECMA-262
    (?:
      [Tt\x20] # T in ECMA-262
      ([0-9]+) : ([0-9]+) # [0-9]{2} in ECMA-262
      (?: : ([0-9]+) # [0-9]{2} in ECMA-262
       (?: (\.[0-9]+) )? # [0-9]{3} in ECMA-262
      )?
      (
        [Zz] | # Z in ECMA-262
        ([+-][0-9]{2})(:?)([0-9]{2}) # : required in ECMA-262
      )?
    )?
  \z}x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $z, $zh, $zc, $zm)
        = ($1, $2, $3, $4 || 0, $5 || 0, $6 || 0, $7, $8, $9, $10, $11);
    if (not defined $M or not defined $d) {
      $M ||= 1;
      $d ||= 1;
    } elsif ($y =~ /^[+-]/ or 2 < length $y) {
      #
    } elsif (2 < length $d) {
      ($y, $M, $d) = ($d, $y, $M);
    } else {
      #
    }

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
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    $sf = defined $sf ? $sf : '';
    if (defined $zh) {
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return undef
        if $zh > 23 or $zh < -23;
      $self->onerror->(type => 'tz:syntax error',
                       level => 'm') # no return
          if not $zc;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return undef
        if $zm > 59;
      if ($zh eq '-00' and $zm eq '00') {
        $self->onerror->(type => 'datetime:-00:00',
                         level => 'm'); # don't return
      }
    } elsif (defined $z) {
      $zh = 0;
      $zm = 0;
    }
    return $self->_create
        ({year => 1, month => 1, day => 1, time => 1, offset => defined $zh},
         $y, $M, $d, $h, $m, $s, $sf, $zh, $zm);

  ## XXX It seems that browsers support more formats, including
  ## English month names and named time zone offsets...

  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_js_date_time_string

sub parse_ogp_date_time_string ($$) {
  my ($self, $value) = @_;
  
  if ($value =~ s/([a-z])/uc $1/ge) {
    $self->onerror->(type => 'datetime:lowercase designator',
                     value => $1,
                     level => 'w');
  }

  if ($value =~ /\x{2010}/) {
    $self->onerror->(type => 'datetime:hyphen',
                     level => 'w');
  }
  if ($value =~ /\x{2212}/) {
    $self->onerror->(type => 'datetime:minus sign',
                     level => 'w');
  }

  if ($value =~ /\A(?:
    ([0-9]{4}|[+\x{2212}-][0-9]{4,})[-\x{2010}]([0-9]{2})[-\x{2010}]([0-9]{2})
    (?:T? ([0-9]{2}):([0-9]{2}) )?
  |
    ([0-9]{4}|[+\x{2212}-][0-9]{4,})([0-9]{2})([0-9]{2})
    (?:T? ([0-9]{2})([0-9]{2}) )?
  )\z/x) {
    my ($y, $M, $d, $h, $m) = ($1, $2, $3, $4 || $9 || 0, $5 || $10 || 0);
    $y = $6 if not defined $y;
    $M = $7 if not defined $M;
    $d = $8 if not defined $d;
    my $has_time = defined $4 || defined $9;
    $y =~ s/\x{2212}/-/g;
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
    if ($y =~ /^[+-]/) {
      $self->onerror->(type => 'datetime:expanded year',
                       value => $y,
                       level => 'w');
    }
    if ($y <= 1582) {
      $self->onerror->(type => 'datetime:pre-gregorio year',
                       value => $y,
                       level => 'w');
    }
    $self->onerror->(type => 'datetime:bad hour',
                     value => $h,
                     level => 'm'), return undef if $h > 23;
    $self->onerror->(type => 'datetime:bad minute',
                     value => $m,
                     level => 'm'), return undef if $m > 59;
    return $self->_create
        ({year => 1, month => 1, day => 1, time => $has_time},
         $y, $M, $d, $h, $m, 0, '', undef, undef);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_ogp_date_time_string

sub parse_w3c_dtf_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ([0-9]{4,})
    (?:-([0-9]{2})
      (?:-([0-9]{2})
        (?:
          T
          ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)?
          (?>Z|([+-][0-9]{2})(:?)([0-9]{2}))
        )?
      )?
    )?
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zc, $zm)
        = ($1, $2, $3, $4 || 0, $5 || 0, $6 || 0, $7, $8, $9, $10);
    my $has_month = defined $2;
    my $has_day = defined $3;
    my $has_time = defined $4;
    $M = 1 if not defined $2;
    $d = 1 if not defined $3;
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
    $self->onerror->(type => 'datetime:bad second',
                     value => $s,
                     level => 'm'), return undef if $s > 59;
    $sf = defined $sf ? $sf : '';
    if (defined $zh) {
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return undef
          if $zh > 23 or $zh < -23;
      $self->onerror->(type => 'tz:syntax error',
                       level => 'm') # no return
          if not $zc;
      $self->onerror->(type => 'datetime:bad timezone minute',
                       value => $zm,
                       level => 'm'), return undef
          if $zm > 59;
    } else {
      $zh = 0;
      $zm = 0;
    }
    return $self->_create
        ({year => 1, month => $has_month, day => $has_day,
          time => $has_time, offset => $has_time},
         $y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_w3c_dtf_string

## Parse a date or time string
## <https://www.whatwg.org/specs/web-apps/current-work/#parse-a-date-or-time-string>
## but time-only string is not allowed
## <https://www.whatwg.org/specs/web-apps/current-work/#attr-mod-datetime>
sub parse_date_string_with_optional_time ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    ([0-9]{4,})-([0-9]{2})-([0-9]{2})
    (?:[T\x20]
      ([0-9]{2}):([0-9]{2})(?>:([0-9]{2})(?>(\.[0-9]+))?)?
      (?>Z|([+-][0-9]{2})(:?)([0-9]{2})))?
  \z/x) {
    my ($y, $M, $d, $h, $m, $s, $sf, $zh, $zc, $zm)
        = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
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
        $self->onerror->(type => 'tz:syntax error',
                         level => 'm') # no return
            if not $zc;
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
      }
      return $self->_create
          ({year => 1, month => 1, day => 1, time => 1, offset => 1},
           $y, $M, $d, $h, $m, $s, $sf, $zh, $zm);
    } else {
      ## A valid date string
      return $self->_create
          ({year => 1, month => 1, day => 1},
           $y, $M, $d, 0, 0, 0, 0, undef, undef);
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
        return Web::DateTime::Interval->new_from_start_and_end ($dt1, $dt2);
      } else {
        $self->onerror->(type => 'interval:not 1<=2',
                         level => 'm');
        return undef;
      }
    } else {
      my $duration = $self->parse_vevent_duration_string ($v2) or return undef;
      require Web::DateTime::Interval;
      return Web::DateTime::Interval->new_from_start_and_duration
          ($dt1, $duration);
    }
  } else {
    return $self->parse_date_string_with_optional_time ($v1);
  }
} # parse_date_string_with_optional_time_and_duration

sub parse_html_datetime_value ($$) {
  my ($self, $value) = @_;
  if ($value =~ /^[0-9]{4,}$/) {
    return $self->parse_year_string ($value);
  } elsif ($value =~ /^[0-9]{4,}\W[0-9]+$/) {
    return $self->parse_month_string ($value);
  } elsif ($value =~ /^[0-9]{4,}\W[0-9]+\W[0-9]+$/) {
    return $self->parse_date_string ($value);
  } elsif ($value =~ /^[0-9]{4,}\W[0-9]+\W[0-9]+.[0-9]+\W[0-9]+/) {
    if ($value =~ /Z$/ or $value =~ /[+-](?:[0-9]+\W[0-9]+|[0-9]{4,})$/) {
      return $self->parse_global_date_and_time_string ($value);
    } else {
      return $self->parse_local_date_and_time_string ($value);
    }
  } elsif ($value =~ /^[0-9]+:[0-9]+/) {
    return $self->parse_time_string ($value);
  } elsif ($value eq 'Z' or
           $value =~ /^[+-](?:[0-9]+\W[0-9]+|[0-9]{4,})$/) {
    return $self->parse_time_zone_offset_string ($value);
  } elsif ($value =~ /^-*[0-9]{1,2}\W[0-9]{1,2}$/) {
    return $self->parse_yearless_date_string ($value);
  } elsif ($value =~ /^[0-9]{4,}\W[Ww]/) {
    return $self->parse_week_string ($value);
  } else {
    return $self->parse_duration_string ($value);
  }
} # parse_html_datetime_value

## ------ Time zone ------

sub parse_time_zone_offset_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A(?:
    Z
    |
    ([+-])([0-9]{2})(:?)([0-9]{2})
  )\z/x) {
    my ($zs, $zh, $zc, $zm) = ($1, $2, $3, $4);
    if (defined $zh) {
      $zs .= '1';
      $self->onerror->(type => 'datetime:bad timezone hour',
                       value => $zh,
                       level => 'm'), return undef
          if $zh > 23;
      $self->onerror->(type => 'tz:syntax error',
                       level => 'm') # no return
          if not $zc;
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

sub parse_vcard_time_zone_offset_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A(?:
    ([+-])([0-9]{2})(:?)([0-9]{2})
  )\z/x) {
    my ($zs, $zh, $zc, $zm) = ($1, $2, $3, $4);
    $zs .= '1';
    $self->onerror->(type => 'datetime:bad timezone hour',
                     value => $zh,
                     level => 'm'), return undef
        if $zh > 23;
    $self->onerror->(type => 'tz:syntax error',
                     level => 'm') # no return
        if not $zc;
    $self->onerror->(type => 'datetime:bad timezone minute',
                     value => $zm,
                     level => 'm'), return undef
        if $zm > 59;
    require Web::DateTime::TimeZone;
    return Web::DateTime::TimeZone->new_from_offset ($zs * ($zh * 60 * 60 + $zm * 60));
  } else {
    $self->onerror->(type => 'tz:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_vcard_time_zone_offset_string

sub _create {
  shift;
  return Web::DateTime->_create (@_);
} # _create

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

sub parse_iso8601_duration_string ($$) {
  my ($self, $value) = @_;

  if ($value =~ /\./) {
    $self->onerror->(type => 'decimal sign:period',
                     level => 'w');
  }
  $value =~ s/,/./g;
  if ($value =~ /\./) {
    $self->onerror->(type => 'duration:fraction',
                     level => 'w');
  }

  if ($value =~ s/([a-z])/uc $1/ge) {
    $self->onerror->(type => 'datetime:lowercase designator',
                     value => $1,
                     level => 'w');
  }

  if ($value =~ /\x{2010}/) {
    $self->onerror->(type => 'datetime:hyphen',
                     level => 'w');
  }
  if ($value =~ /\x{2212}/) {
    $self->onerror->(type => 'datetime:minus sign',
                     level => 'w');
  }


  if ($value =~ /^P([+-][0-9]+)/) {
    $self->onerror->(type => 'datetime:expanded year',
                     value => $1,
                     level => 'w');
  }

  my $months = 0;
  my $seconds = 0;
  if ($value =~ /\A
    P
    (?:([0-9]+)Y)?
    (?:([0-9]+)M)?
    (?:([0-9]+)D)?
    (?:T
      (?:([0-9]+)H)?
      (?:([0-9]+)M)?
      (?:([0-9]+(?:[.][0-9]+|))S)
    )
  \z/x) {
    $months += $1 * 12 if defined $1;
    $months += $2 if defined $2;
    $seconds += $3 * $DurationScale->{D} if defined $3;
    $seconds += $4 * $DurationScale->{H} if defined $4;
    $seconds += $5 * $DurationScale->{M} if defined $5;
    $seconds += $6 * $DurationScale->{S} if defined $6;
  } elsif ($value =~ /\AP([0-9]+(?:[.][0-9]+|))W\z/) {
    $seconds += $1 * $DurationScale->{W};
  } elsif ($value =~ /\A
    P
    (?:([0-9]+)Y)?
    (?:([0-9]+)M)?
    (?:([0-9]+)D)?
    (?:T
      (?:([0-9]+)H)?
      (?:([0-9]+(?:[.][0-9]+|))M)
    )
  \z/x) {
    $months += $1 * 12 if defined $1;
    $months += $2 if defined $2;
    $seconds += $3 * $DurationScale->{D} if defined $3;
    $seconds += $4 * $DurationScale->{H} if defined $4;
    $seconds += $5 * $DurationScale->{M} if defined $5;
  } elsif ($value =~ /\A
    P
    (?:([0-9]+)Y)?
    (?:([0-9]+)M)?
    (?:([0-9]+)D)?
    (?:T
      (?:([0-9]+(?:[.][0-9]+|))H)
    )
  \z/x) {
    $months += $1 * 12 if defined $1;
    $months += $2 if defined $2;
    $seconds += $3 * $DurationScale->{D} if defined $3;
    $seconds += $4 * $DurationScale->{H} if defined $4;
  } elsif ($value =~ /\A
    P
    (?:([0-9]+)Y)?
    (?:([0-9]+)M)?
    (?:([0-9]+(?:[.][0-9]+|))D)
  \z/x) {
    $months += $1 * 12 if defined $1;
    $months += $2 if defined $2;
    $seconds += $3 * $DurationScale->{D} if defined $3;
  } elsif ($value =~ /\A
    P
    (?:([0-9]+)Y)?
    (?:([0-9]+(?:[.][0-9]+|))M)
  \z/x) {
    $months += $1 * 12 if defined $1;
    $months += $2 if defined $2;
  } elsif ($value =~ /\A
    P
    (?:([0-9]+(?:[.][0-9]+|))Y)
  \z/x) {
    $months += $1 * 12 if defined $1;
  } elsif ($value =~ /\AP([0-9]+(?:[.][0-9]+|))W\z/) {
    $seconds += $1 * $DurationScale->{W};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}](0[0-9]|1[01])[-\x{2010}]([0-2][0-9])
    T?([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D}
              + $4 * $DurationScale->{H}
              + $5 * $DurationScale->{M}
              + $6 * $DurationScale->{S};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}]([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
    T?([01][0-9]|2[0-3]):([01][0-9]|2[0-3]):([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D}
              + $3 * $DurationScale->{H}
              + $4 * $DurationScale->{M}
              + $5 * $DurationScale->{S};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}](0[0-9]|1[01])[-\x{2010}]([0-2][0-9])
    T?([01][0-9]|2[0-3]):([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D}
              + $4 * $DurationScale->{H}
              + $5 * $DurationScale->{M};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}]([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
    T?([01][0-9]|2[0-3]):([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D}
              + $3 * $DurationScale->{H}
              + $4 * $DurationScale->{M};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}](0[0-9]|1[01])[-\x{2010}]([0-2][0-9])
    T?((?:[01][0-9]|2[0-3])(?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D}
              + $4 * $DurationScale->{H};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}]([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
    T?((?:[01][0-9]|2[0-3])(?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D}
              + $3 * $DurationScale->{H};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}](0[0-9]|1[01])[-\x{2010}]([0-2][0-9])
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}]([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})[-\x{2010}](0[0-9]|1[01])
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})(0[0-9]|1[01])([0-2][0-9])
    T?([01][0-9]|2[0-3])([0-5][0-9])([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D}
              + $4 * $DurationScale->{H}
              + $5 * $DurationScale->{M}
              + $6 * $DurationScale->{S};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
    T?([01][0-9]|2[0-3])([01][0-9]|2[0-3])([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D}
              + $3 * $DurationScale->{H}
              + $4 * $DurationScale->{M}
              + $5 * $DurationScale->{S};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})(0[0-9]|1[01])([0-2][0-9])
    T?([01][0-9]|2[0-3])([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D}
              + $4 * $DurationScale->{H}
              + $5 * $DurationScale->{M};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
    T?([01][0-9]|2[0-3])([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D}
              + $3 * $DurationScale->{H}
              + $4 * $DurationScale->{M};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})(0[0-9]|1[01])([0-2][0-9])
    T?((?:[01][0-9]|2[0-3])(?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D}
              + $4 * $DurationScale->{H};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
    T?((?:[01][0-9]|2[0-3])(?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D}
              + $3 * $DurationScale->{H};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})(0[0-9]|1[01])([0-2][0-9])
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D}
              + $3 * $DurationScale->{D};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})([0-2][0-9][0-9]|3[0-5][0-9]|36[0-4])
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * $DurationScale->{D};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})(0[0-9]|1[01])
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D}
              + $2 * 30 * $DurationScale->{D};
  } elsif ($value =~ /\A
    P([0-9]{4}|\+[0-9]{4,})
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 12 * 30 * $DurationScale->{D};
  } elsif ($value =~ /\A
    P([0-9]{2}|\+[0-9]{2,})
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * 100 * 12 * 30 * $DurationScale->{D};
  } elsif ($value =~ /\A
    PT([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * $DurationScale->{H}
              + $2 * $DurationScale->{M}
              + $3 * $DurationScale->{S};
  } elsif ($value =~ /\A
    PT([01][0-9]|2[0-3]):([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * $DurationScale->{H}
              + $2 * $DurationScale->{M};
  } elsif ($value =~ /\A
    PT((?:[01][0-9]|2[0-3])(?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * $DurationScale->{H};
  } elsif ($value =~ /\A
    PT([01][0-9]|2[0-3])([0-5][0-9])([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * $DurationScale->{H}
              + $2 * $DurationScale->{M}
              + $3 * $DurationScale->{S};
  } elsif ($value =~ /\A
    PT([01][0-9]|2[0-3])([0-5][0-9](?:\.[0-9]+|))
  \z/x) {
    $self->onerror->(type => 'duration:alternative',
                     level => 'w');
    $seconds += $1 * $DurationScale->{H}
              + $2 * $DurationScale->{M};
  } else {
    $self->onerror->(type => 'duration:syntax error',
                     level => 'm');
    return undef;
  }

  require Web::DateTime::Duration;
  return Web::DateTime::Duration->new_from_seconds_and_months_and_sign
      ($seconds, $months, +1);
} # parse_iso8601_duration_string

## ------ Time ranges ------

my %WdayNum = (Su => 0, Mo => 1, Tu => 2, We => 3, Th => 4, Fr => 5, Sa => 6);

sub parse_weekly_time_range_string ($$) {
  my ($self, $value) = @_;
  if ($value =~ /\A
    (?:Su|Mo|Tu|We|Th|Fr|Sa)(?:-(?:Su|Mo|Tu|We|Th|Fr|Sa))?
    (?:,(?:Su|Mo|Tu|We|Th|Fr|Sa)(?:-(?:Su|Mo|Tu|We|Th|Fr|Sa))?)*
    (?:
      \x20
      (?:[01][0-9]|2[0-3]):[0-5][0-9]-(?:[01][0-9]|2[0-3]):[0-5][0-9]
      (?:,(?:[01][0-9]|2[0-3]):[0-5][0-9]-(?:[01][0-9]|2[0-3]):[0-5][0-9])*
    )?
  \z/x) {
    my ($days, $times) = split / /, $value;
    my $wdays = [];
    for (split /,/, $days) {
      if (/^([A-Za-z]+)-([A-Za-z]+)$/) {
        my $start = $WdayNum{$1};
        my $end = $WdayNum{$2};
        if ($start <= $end) {
          $wdays->[$_] = 1 for $start..$end
        } else {
          $wdays->[$_ % 7] = 1 for $start..($end + 7);
        }
      } else {
        $wdays->[$WdayNum{$_}] = 1;
      }
    }
    my $ranges = [];
    for (split /,/, $times || '') {
      /^([0-9]+):([0-9]+)-([0-9]+):([0-9]+)$/;
      push @$ranges, [$1*60+$2 => $3*60+$4];
    }
    require Web::DateTime::WeeklyTimeRange;
    return Web::DateTime::WeeklyTimeRange->new_from_weekdays_and_time_ranges
        ($wdays, $ranges);
  } else {
    $self->onerror->(type => 'datetime:syntax error',
                     level => 'm');
    return undef;
  }
} # parse_weekly_time_range_string

1;

=head1 LICENSE

Copyright 2008-2018 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
