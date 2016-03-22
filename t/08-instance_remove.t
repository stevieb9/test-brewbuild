#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;
my $remove_cmd = $mock->mock('Test::BrewBuild::BrewCommands::remove');
$remove_cmd->return_value('echo "install"');

if ($^O =~ /MSWin/) {
    my $bb = Test::BrewBuild->new;
    my $ok = eval { $bb->instance_remove('5.22.1_64'); 1; };
    is ($remove_cmd->called, 1, "win: BrewCommands::remove() called");
    is ($ok, 1, "win: instance_remove() ok");
}
else {
    my $bb = Test::BrewBuild->new;
    my $ok = eval {
        $bb->instance_remove( qw(5.8.9) ); 1; };
    is ($remove_cmd->called, 1, "nix: BrewCommands::install() called");
    is ( $ok, 1, "nix: instance_remove() ok" );
}

done_testing();

