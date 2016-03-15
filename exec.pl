#!/usr/bin/perl
use warnings;
use strict;

if ($^O ne 'MSWin32'){
    system "cpanm --installdeps . && make && make test";
}
else {
    system "cpanm --installdeps . && dmake && dmake test";
}
