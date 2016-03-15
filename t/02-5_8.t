#!/usr/bin/perl
use warnings;
use strict;

use Test::More;

if ($] =~ /5\.00[68]/){
    my $x;
    my @a = qw(1);
    my @b = qw(2);
    eval "@a ~~ @b";
    
    like ($@, qr/syntax error/, "confirmed we cross perls");
}
else {
    plan skip_all => "this is a v5.8.x test only";
}
done_testing();
