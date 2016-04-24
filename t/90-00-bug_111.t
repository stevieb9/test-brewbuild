#!/usr/bin/perl
use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path qw(remove_tree);
use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $cwd = getcwd();
my $tdir = 't/bug_111';

mkdir $tdir or die $!;
chdir $tdir;

my $ret = `brewbuild -r -i 5.20.3`;

like ($ret, qr/there's no 't\/' directory/, "remove/install works before no t/");

chdir $cwd;
remove_tree $tdir or die $!;

done_testing();

