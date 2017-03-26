#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use File::Path qw(remove_tree);
use Test::BrewBuild::Git;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $mod = 'Test::BrewBuild::Git';
my $wdir = "t/repo";
my $cwd = getcwd();

mkdir $wdir or die $! if ! -d $wdir;

{ #new
    my $git = $mod->new;
    is (ref $git, $mod, "obj is a $mod");
}
{ # link
    my $git = $mod->new;
    my $link = $git->link;

    like (
        $link,
        qr{github.com/stevieb9/test-brewbuild},
        "link is correct",
    );
}
{ # clone & name & pull

    my $git = $mod->new;
    my $link = $git->link;
    my $name = $git->name($link);

    chdir $wdir or die $!;

    is ($name, 'test-brewbuild', "name of repo dir is ok");

    my $ret = $git->clone($link);
    like ($ret, qr/Cloning into/, "clone() ok");
    is (-d $name, 1, "repo dir created ok via clone");

    chdir $name or die $!;
    $ret = $git->pull;
    print $ret;
}

chdir $cwd or die $!;
remove_tree $wdir or die $!;
is (-d $wdir, undef, "removed work dir ok");

done_testing();

