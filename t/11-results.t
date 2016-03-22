#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $out;
open my $stdout, '+>', \$out or die $!;
select $stdout;

my $bb = Test::BrewBuild->new;

my $mock = Mock::Sub->new(debug => 7);
my $exec = $mock->mock('Test::BrewBuild::exec');

my $good = "perl-5.20.3 Result: PASS\n";
my $bad  = "perl-5.20.3 Result: FAIL\n";

{ # good
    my $out;
    open my $stdout, '>', \$out or die $!;
    select $stdout;
    $exec->return_value($good);
    $bb->results;
    select STDOUT;
    close $stdout;

    like ($out, qr/PASS/, "good results PASS");
}
{ # bad
    my $out;
    open my $stdout, '>', \$out or die $!;
    select $stdout;
    $exec->return_value($bad);
    $bb->results;
    select STDOUT;
    close $stdout;

    like ($out, qr/FAIL/, "bad results FAIL");
}

done_testing();
