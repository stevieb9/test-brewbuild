#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

if ($^O =~ /MSWin/) {
    my $bb = Test::BrewBuild->new;
    my $ok = eval { $bb->instance_remove(qw(5.22.1_32)); 1; };
    is ($ok, 1, "win: instance_remove() ok");
}
else {
    my $bb = Test::BrewBuild->new;
    my $ok = eval {
        $bb->instance_remove( qw(5.8.9) ); 1; };
    is ( $ok, 1, "nix: instance_remove() ok" );
}

done_testing();

