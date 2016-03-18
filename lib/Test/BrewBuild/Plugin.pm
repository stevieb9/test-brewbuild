package Test::BrewBuild::Plugin;
use strict;
use warnings;

use ExtUtils::Installed;
use Logging::Simple;
use Module::Load;

our $VERSION = '0.05';

my $log;

BEGIN {
    no strict 'refs';
    no warnings 'redefine';

    *Test::BrewBuild::plugin = sub {
        my ($obj, $check, $local) = @_;

        $log = $obj->log()->child('Plugin.plugin');

        # $log->level(7);

        $log->_7("ref obj: " . ref $obj);
        $log->_7("looking for plugin: $check") if $check;
        $log->_7("looking for plugin locally") if $local;

        if (! $local) {
            return _load_plugin($check);
        }
        return _local_load_plugin($check);
    };
};

sub _load_plugin {
    my $plugin = shift;

    $log->_7("in _load_plugin()");

    my $inst = ExtUtils::Installed->new;
    my @modules = $inst->modules;

    if ($plugin && grep { $_ eq $plugin } @modules) {

        load $_;
        $log->_7("loaded $_ plugin");

        if ($_->can('brewbuild_exec')){
            $log->_7("brewbuild_exec() found in plugin");
            return $plugin;
        }
    }
    else {
        $log->_7("using default plugin");
        $plugin = 'Test::BrewBuild::Plugin::DefaultExec';
        load $plugin;
        return $plugin;
    }
}
sub _local_load_plugin {
    my $plugin = shift;

    $log->_7("in _local_load_plugin()");

    load $plugin;

    if ($plugin->can('brewbuild_exec')){
        $log->_7("brewbuild_exec found in local plugin");

        return $plugin;
    }
    else {
        $log->_7("plugin not found in local... using default plugin");
        $plugin = 'Test::BrewBuild::Plugin::DefaultExec';
        load $plugin;
        return $plugin;
    }
}
1;
