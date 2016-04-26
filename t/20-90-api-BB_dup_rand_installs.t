#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Mock::Sub;
use Test::BrewBuild;
use Test::BrewBuild::BrewCommands;
use Test::More;

my $m = Mock::Sub->new;
my $inst = $m->mock('Test::BrewBuild::BrewCommands::install');
my $rem = $m->mock('Test::BrewBuild::BrewCommands::remove'); # in case of error

$inst->return_value('echo');

my $bb = Test::BrewBuild->new(notest => 1);

my $stdout = capture_stdout {
    $bb->instance_install(10);
};
$inst->unmock;
$rem->unmock;

my @ret = split /\n/, $stdout;
chomp @ret;

my %count;
map {$count{$_}++} @ret;

for (keys %count){
    is ($count{$_}, 1, "$_ installed only once");
}

done_testing();

