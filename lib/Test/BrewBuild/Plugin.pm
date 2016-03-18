package Test::BrewBuild::Plugin;
use strict;
use warnings;

use Data::Dumper;
use ExtUtils::Installed;
use Logging::Simple;
use Module::Load;

our $VERSION = '0.05';

my $log_lvl = 0;

BEGIN {
    no strict 'refs';
    no warnings 'redefine';

    *Test::BrewBuild::plugin = sub {
        my ($self, $check) = @_;
        return _load_plugin($check);
    };
};

sub _load_plugin {
    my $plugin = shift;

    my $inst = ExtUtils::Installed->new;
    my @modules = $inst->modules;

    if (grep { $_ eq $plugin } @modules) {
        load $_;
        if ($_->can( 'brewbuild_exec' )) {
            return $plugin;
        }
    }
    else {
        $plugin = 'Test::BrewBuild::Plugin::DefaultExec';
        load $plugin;
        return $plugin;
    }
}

1;
