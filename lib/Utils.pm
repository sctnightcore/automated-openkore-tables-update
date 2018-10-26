package Utils;

use strict;
use warnings;
use File::Path qw(make_path);

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub createDir() {
    my ($self, $dir) = @_;
    eval { make_path($dir) };
    if ($@) {
      print "Couldn't create $dir: $@";
    }
}

1;