#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

{

    my $bb = Test::BrewBuild->new( notest => 1 );
    my @rd = $bb->_get_revdeps('Mock-Sub');

    is (@rd, 3, 'proper count of revdeps');

    is ((grep {$_ eq 'Devel::Examine::Subs'} @rd), 1, "DES included");
    is ((grep {$_ eq 'Devel::Trace::Subs'} @rd), 1, "DTS included");
    is ((grep {$_ eq 'File::Edit::Portable'} @rd), 1, "FEP included");
}

done_testing();

