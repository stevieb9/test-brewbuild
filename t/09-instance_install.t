#!/usr/bin/perl
use strict;
use warnings;

use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;
my $inst_cmd = $mock->mock('Test::BrewBuild::BrewCommands::install');
$inst_cmd->return_value('echo "install"');

if ($^O =~ /MSWin/) {
    my $bb = Test::BrewBuild->new;
    my $ok = eval {
        $bb->instance_install(1, [qw(5.18.4_64 5.16.3_64)], [qw(5.18.4_64)]);
        1;
    };
    is ($inst_cmd->called, 1, "win: BrewCommands::install() called");
    is ($ok, 1, "win: instance_install() ok");
}
else {
    my $bb = Test::BrewBuild->new;
    my $ok = eval {
        $bb->instance_install( qw(5.8.9) ); 1; };
    is ($inst_cmd->called, 1, "nix: BrewCommands::install() called");
    is ( $ok, 1, "nix: instance_install() ok" );
}

done_testing();

