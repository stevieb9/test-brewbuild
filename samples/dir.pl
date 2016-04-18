#!/usr/bin/perl
use strict;
use warnings;

use feature 'say';
use Config::Tiny;
use Data::Dumper;

my $conf = Config::Tiny->read("conf/brewbuild.conf")->{dispatch};

$conf->{testers} =~ s/\s+//;
my $testers = [ split /,/, $conf->{testers} ];

print Dumper $testers;

