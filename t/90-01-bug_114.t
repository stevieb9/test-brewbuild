#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $bb = Test::BrewBuild->new;

$bb->instance_remove;
$bb->instance_install([qw(5.10.1_32)]);

my @installed = $bb->perls_installed;

is ((grep {$_ =~ /5\.10\.1/} @installed), 1, "5.10.1 installed even with _32");

done_testing();

