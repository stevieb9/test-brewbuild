#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use File::Path qw(remove_tree);
use Test::BrewBuild::Git;
use Test::More;

my $mod = 'Test::BrewBuild::Git';

{ # revision

    my $git = $mod->new;

    my $csum = $git->revision;

    print "$csum\n";

}

done_testing();

