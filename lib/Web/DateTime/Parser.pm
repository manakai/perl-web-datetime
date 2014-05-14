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
  if ($dt->year != $y or
      $dt->month != $M or
      $dt->day != $d or
      $dt->hour != $h or
      $dt->minute != $m) {
    ## Too large or small
    #warn $dt->to_global_date_and_time_string;
    $self->onerror->(type => 'date value not supported',
                     value => join (", ", map { defined $_ ? $_ : '' } $y, $M, $d, $h, $m, $s, $sf, $zh, $zm, $diff),
                     level => 'u');
    # XXX 0001-0999
    return undef;
  }}

  return $dt;
} # _create

# XXX parser for HTML <time> value

1;

=head1 LICENSE

Copyright 2008-2014 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
