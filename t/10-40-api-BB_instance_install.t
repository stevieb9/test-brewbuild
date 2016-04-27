#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Mock::Sub;
use Test::BrewBuild;
use Test::More;

my $mock = Mock::Sub->new;
my $inst_cmd = $mock->mock('Test::BrewBuild::BrewCommands::install');
$inst_cmd->return_value('echo "install"');

{ # rand dups

    my $bb = Test::BrewBuild->new(notest => 1);

    my $stdout = capture_stdout {
        $bb->instance_install(10);
    };

    my @ret = split /\n/, $stdout;
    chomp @ret;

    my %count;
    map {$count{$_}++} @ret;

    for (keys %count){
        is ($count{$_}, 1, "$_ installed only once");
    }

    $inst_cmd->reset;
}

my $out;
open my $stdout, '>', \$out or die $!;
select $stdout;

if ($^O =~ /MSWin/) {
    { # default install
        my $bb = Test::BrewBuild->new;
        my $ok = eval {
            $bb->instance_install([qw(5.18.4_64 5.16.3_64)], [qw(5.18.4_64)]);
            1;
        };
        is ($inst_cmd->called, 1, "win: BrewCommands::install() called");
        is ($ok, 1, "win: instance_install() ok");

        $inst_cmd->reset;
    }
    { # version install
        my $bb = Test::BrewBuild->new;
        my $ok = eval {
            $bb->instance_install([qw(5.18.4_64 5.18.4_32)], [qw(5.18.4_32)]);
            1;
        };
        is ($inst_cmd->called, 1, "win: BrewCommands::install() called w/ ver");
        is ($ok, 1, "win: instance_install() with version ok");
    }
    { # no @new_installs
        my $bb = Test::BrewBuild->new;
        my $ok = eval {
            $bb->instance_install([qw(5.18.4_64 5.18.4_32)], [qw(5.18.4_32)]);
            1;
        };
        is ($inst_cmd->called, 1, "win: BrewCommands::install() called w/ no new vers");
        is ($ok, 1, "win: instance_install() does nothing if nothing to install");
    }
}
else {
    { # default install
        my $bb = Test::BrewBuild->new;
        my $ok = eval {
            $bb->instance_install(1);
            1;
        };
        is ( $inst_cmd->called, 1, "nix: BrewCommands::install() called" );
        is ( $ok, 1, "nix: instance_install() ok" );
    }
    { # version install
        my $bb = Test::BrewBuild->new;
        my $ok = eval {
            $bb->instance_install([qw(5.18.4 5.20.0)], [qw(5.20.0)]);
            1;
        };
        is ($inst_cmd->called, 1, "nix: BrewCommands::install() called w/ ver");
        is ($ok, 1, "nix: instance_install() with version ok");
    }
     { # no @new_installs
        my $bb = Test::BrewBuild->new;
        my $ok = eval {
            $bb->instance_install([qw(5.18.4_64 5.18.4_32)], [qw(5.18.4_32)]);
            1;
        };
        is ($inst_cmd->called, 1, "nix: BrewCommands::install() called w/ no new vers");
        is ($ok, 1, "nix: instance_install() does nothing if nothing to install");
    }
}


for ($mock->mocked_objects){
    $_->unmock;
    is ($_->mocked_state, 0, $_->name ." has been unmocked ok");
}

select STDOUT;

done_testing();

