#!/usr/bin/perl
use warnings;
use strict;

use Cwd;

#my $cwd = getcwd();
#print "$cwd\n";

print "*** $^V\n";

if ($^O ne 'MSWin32'){
    system "cpanm --installdeps . && make && make test";
}
else {
    system "cpanm --installdeps . && dmake && dmake test";
}