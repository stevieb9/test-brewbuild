#!/usr/bin/perl
use strict;
use warnings;

use File::Copy;
use Test::BrewBuild;
use Test::More;

my $mod = 'Test::BrewBuild';
my $bb = $mod->new;

{ # default plugin
    my $plugin = $bb->plugins('Test::BrewBuild::Plugin::DefaultExec');

    is (
        $plugin,
        'Test::BrewBuild::Plugin::DefaultExec',
        "calling the bundled plugin directly ok",
    );
}
{ # bad plugin
    my $plugin = $bb->plugins();

    is (
        $plugin,
        'Test::BrewBuild::Plugin::DefaultExec',
        "calling for a bad plugin results in the default",
    );
}
{ # tests good plugin
    my $plugin = $bb->plugins('Test::BrewBuild::Plugin::UnitTestPluginInst');

    is (
        $plugin,
        'Test::BrewBuild::Plugin::UnitTestPluginInst',
        "calling for a good plugin works (so does local)",
    );
}
{ # test path-based plugin
    my $plugin = $bb->plugins('t/base/UnitTestPlugin.pm');

    is (
        $plugin,
        'UnitTestPlugin',
        "calling for a path-based plugin ok)",
    );
}
{ # test cwd path-based plugin
    copy 't/base/UnitTestPlugin.pm', 'UnitTestPlugin.pm';

    my $plugin = $bb->plugins('UnitTestPlugin.pm');

    is (
        $plugin,
        'UnitTestPlugin',
        "calling for a cwd file plugin ok)",
    );

    unlink 'UnitTestPlugin.pm';
    is (-e 'UnitTestPlugin.pm', undef, "unlinked TestPlugin.pm ok");
}
{ # test no param
    my $plugin = $bb->plugins;

    is (
        $plugin,
        'Test::BrewBuild::Plugin::DefaultExec',
        "calling plugin() with no params returns the derfault plugin",
    );
}
{ # test content of default plugin
    my $plugin = $bb->plugins;
    my @ret = $plugin->brewbuild_exec;
    my @data = <DATA>;

    is (@ret, @data, "default plugin returns the correct num of lines of code");

    my $i = 0;
    for (@ret){
        is ($_, $data[$i], "plugin line $i matches base line $i");
        $i++;
    }
}

done_testing();

__DATA__
system "cpanm --installdeps . && cpanm --test-only .";
