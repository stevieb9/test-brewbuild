#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild;
my %opts = Test::BrewBuild->options(['--return', '-d', '7']);

my $bb = Test::BrewBuild->new(%opts);

my $ret = $bb->run;

print $ret;
