package Test::BrewBuild::Plugin;
use strict;
use warnings;

use ExtUtils::Installed;
use Module::Load;

my $inst = ExtUtils::Installed->new;

BEGIN {
    no strict 'refs';
    no warnings 'redefine';

    *Test::BrewBuild::plugin = sub {
        my ($self, $check) = @_;
        return _get_plugin($check);
    };
};
sub _get_plugin {
    my $plugin = shift;

    my @modules = $inst->modules;

    if (grep { $_ eq $plugin } @modules){
        load $_;
        if ($_->can('brewbuild_exec')){
            return $plugin;
        }
        else {
            return 'Test::BrewBuild::Plugin::DefaultExec';
        }
    }
}
