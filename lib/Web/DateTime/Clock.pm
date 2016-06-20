package Web::DateTime::Clock;
use strict;
use warnings;
our $VERSION = '1.0';
use Time::HiRes qw(time clock_gettime CLOCK_MONOTONIC);

use constant realtime_clock => sub { return time };
use constant monotonic_clock => sub { return clock_gettime (CLOCK_MONOTONIC) };

1;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
