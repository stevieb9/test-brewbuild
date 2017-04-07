#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use File::Path qw(remove_tree);
use Test::BrewBuild::Git;
use Test::More;

my $mod = 'Test::BrewBuild::Git';

{ # _separate_url

    my $git = $mod->new;

    my @res;

    @res = $git->_separate_url;

    is $res[0], 'stevieb9', "user portion of _separate_url ok w/no params";
    like $res[1], qr/test-brewbuild/, "repo portion of _separate_url ok w/no params";

    @res = $git->_separate_url('https://github.com/stevieb9/test-brewbuild');

    is $res[0], 'stevieb9', "user portion of _separate_url ok with repo param";
    like $res[1], qr/test-brewbuild/, "repo portion of _separate_url ok with repo";
}
{ # revision

    my $git = $mod->new;
    my $csum;

    # local
    $csum = $git->revision;
    print "$csum\n";

    # remote
    $csum = $git->revision(remote => 1);
    print "$csum\n";
}

done_testing();

