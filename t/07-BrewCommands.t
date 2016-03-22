#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Logging::Simple;
use Test::BrewBuild::BrewCommands;

my $im_on_windows = ($^O =~ /MSWin/) ? 1 : 0;

my $log = Logging::Simple->new;
my $bc = Test::BrewBuild::BrewCommands->new($log);

is (ref $bc, 'Test::BrewBuild::BrewCommands', 'obj is ok');

if ($im_on_windows){

   is ($bc->brew, 'berrybrew', "win: brew() is ok");

   my $inst = '5.20.3_64       [installed]';
   my @inst = $bc->installed($inst);
   is ($inst[0], "5.20.3_64", "win: installed is ok");

   my $avail = '5.22.1_32_NO64';
   my @avail = $bc->available($avail);
   is ($avail[0], '5.22.1_32', "win: avail with info ok");

   my $res = $bc->available;
   ok ($res || ! $res, "win: available ok");

   my $inst_cmd = $bc->install;
   is ($inst_cmd, 'berrybrew install', "win: install() ok");

   my $remove_cmd = $bc->remove;
   is ($remove_cmd, 'berrybrew remove', "win: remove() ok");

   my $ver = '5.20.3';
   my $newver = $bc->version($ver);
   is ($newver, '5.20.3', "win: version() ok");

   is ($bc->is_win, 1, "win: is win ok");
}
else {
   is ($bc->brew, 'perlbrew', "nix: brew() is ok");

   my $inst = 'i perl-5.22.1';
   my @inst = $bc->installed($inst);
   is ($inst[0], "perl-5.22.1", "nix: installed is ok");

   my $avail = 'perl-5.22.1';
   my @avail = $bc->available($avail);
   is ($avail[0], 'perl-5.22.1', "nix: avail with info ok");

   my $res = $bc->available;
   ok ($res || ! $res, "nix: available ok");

   my $inst_cmd = $bc->install;
   is ($inst_cmd, 'perlbrew install --notest -j 4', "nix: install() ok");

   my $remove_cmd = $bc->remove;
   is ($remove_cmd, 'perlbrew uninstall', "nix: remove() ok");

   my $ver = '5.20.3';
   my $newver = $bc->version($ver);
   is ($newver, 'perl-5.20.3', "nix: version() ok");

   is ($bc->is_win, 0, "nix: is win ok");
}

done_testing();

