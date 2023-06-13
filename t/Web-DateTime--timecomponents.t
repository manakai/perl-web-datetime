use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib')->stringify;
use Test::More;
use Test::X1;
use Test::HTCT::Parser;

use Web::DateTime;
use Web::DateTime::Parser;

my $RootPath = path (__FILE__)->parent->parent;
my $DataPath = $RootPath->child ('t_deps/modules/tests-datetime/timewithref');

for my $path (($DataPath->children (qr/\.dat$/))) {
  for_each_test $path, {
    input => {},
    ref => {},
    output => {},
  }, sub {
    my $test = $_[0];

    test {
      my $c = shift;

      my $dtp = Web::DateTime::Parser->new;
      my $ref = $dtp->parse_global_date_and_time_string ($test->{ref}->[0]);

      $test->{input}->[0] =~ /^\s*(\d+):(\d+)(?::(\d+(?:\.\d+|))|)\s*$/
          or die "Bad input |$test->{input}->[0]|";
      my ($h, $m, $s) = ($1, $2, $3);

      my $dt = Web::DateTime->new_from_time_components ($ref, $h, $m, $s);
      is $dt->to_time_zoned_global_date_and_time_string, $test->{output}->[0];

      done $c;
    } n => 1, name => $test->{name}->[0] // $test->{input}->[0];
  };
} # $path

run_tests;

=head1 LICENSE

Copyright 2023 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
