#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;
my $brew_info = $mock->mock(
    'Test::BrewBuild::brew_info',
    return_value => 1
);
my $perls_available = $mock->mock('Test::BrewBuild::perls_available');
$perls_available->return_value(qw(5.20.0 5.22.1 5.8.9));
my $perls_installed = $mock->mock('Test::BrewBuild::perls_installed');
$perls_installed->return_value(qw(5.20.0));
my $results = $mock->mock('Test::BrewBuild::results', return_value => 'done');

if ($^O =~ /MSWin/){
    { # default
        my $bb = Test::BrewBuild->new;
        my $ret = $bb->run;
        is ($ret, 'done', "win: run() all default ok");

        for ($perls_available, $perls_installed, $results){
            is ($_->called, 1, "win: run() default all subs called");
        }
    }
}
else {
    { # default
        my $bb = Test::BrewBuild->new;
        my $ret = $bb->run;
        is ($ret, 'done', "nix: run() all default ok");

        for ($perls_available, $perls_installed, $results){
            is ($_->called, 1, "nix: run() default all subs called");
        }
    }
}
done_testing();

