#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use File::Path qw(remove_tree);
use Test::BrewBuild::Repo;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $mod = 'Test::BrewBuild::Repo';
my $wdir = "t/repo";
my $cwd = getcwd();

mkdir $wdir or die $! if ! -d $wdir;

{ #new
    my $r = $mod->new;
    is (ref $r, $mod, "obj is a $mod");
}
{ # link
    my $r = $mod->new;
    my $link = $r->link;

    like (
        $link,
        qr{github.com/stevieb9/p5-test-brewbuild},
        "link is correct",
    );

{ # clone & name & pull

    my $r = $mod->new;
    my $link = $r->link;
    my $name = $r->name($link);

    chdir $wdir or die $!;

    is ($name, 'p5-test-brewbuild', "name of repo dir is ok");

    my $ret = $r->clone($link);
    like ($ret, qr/Cloning into/, "clone() ok");
    is (-d $name, 1, "repo dir created ok via clone");

    chdir $name or die $!;
    $ret = $r->pull;
    print $ret;
}

chdir $cwd or die $!;
remove_tree $wdir or die $!;
is (-d $wdir, undef, "removed work dir ok");

done_testing();

