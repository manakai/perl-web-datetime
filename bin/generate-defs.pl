use strict;
use warnings;
use Data::Dumper;
use JSON::PS;
use Path::Tiny;

my $Data = {};

{
  my $src_path = path (__FILE__)->parent->parent->child ('local/datetime-seconds.json');
  my $src = json_bytes2perl $src_path->slurp;
  for (keys %{$src->{positive_leap_seconds}}) {
    $Data->{positive_leap_second_after}->{$src->{positive_leap_seconds}->{$_}->{prev_unix}} = 1;
  }
}

{
  my $src_path = path (__FILE__)->parent->parent->child ('local/timezones-mail-names.json');
  my $src = json_bytes2perl $src_path->slurp;
  $Data->{mail_tz_names} = $src->{names};
}

$Data::Dumper::Sortkeys = 1;
my $dump = Dumper $Data;
$dump =~ s/^\$VAR1/\$Web::DateTime::_Defs/;
print $dump;
print "1;";

## License: Public Domain.
