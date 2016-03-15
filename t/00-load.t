#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::BrewBuild' ) || print "Bail out!\n";
}

print( "Testing Test::BrewBuild $Test::BrewBuild::VERSION, Perl $], $^X" );
