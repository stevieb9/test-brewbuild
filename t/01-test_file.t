#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;


use_ok('Test::BrewBuild');

my $b = Test::BrewBuild->new;
my $test = $b->_test_file;

is (ref $test, 'File::Temp', "test file is a file handle");
is ((split(/\./, $test))[1], 'pl', "test file has a proper name");

done_testing();

