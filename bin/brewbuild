#!/usr/bin/perl
use warnings;
use strict;

use Cwd;
use Getopt::Long;

my ($debug, $count, $reload, $version, $help);

GetOptions(
    "debug=i" => \$debug,
    "count=i" => \$count,
    "reload=i" => \$reload,
    "version=s" => \$version,
    "help"      => \$help,
);

if ($help){
    print <<EOF;
    
    Usage: perl build/brewbuild.pl [options]

    Options:

    --debug | -d:   Bool, enable verbosity
    --count | -c:   Integer, how many random versions of perl to install
    --reload | -r:  Bool, remove all installed perls (less the current one)
                    before installation of new ones
    --verion | -v:  String, the number portion of an available perl version
                    according to "perlbrew available" Note that only one is
                    allowed at this time
    --help | -h:    print this help message
EOF
exit;
}

my $cwd = getcwd();
my $is_win = 0;
$is_win = 1 if $^O =~ /Win/;

run($count);

sub perls_available {
    my $brew_info = shift;

    my @perls_available = $is_win
        ? $brew_info =~ /(\d\.\d+\.\d+_\d+)/g
        : $brew_info =~ /(perl-\d\.\d+\.\d+)/g;

    if ($is_win){
        for (@perls_available){
            s/perl-//;
        }
    }
    return @perls_available;
}
sub perls_installed {
    my $brew_info = shift;

    return $is_win
        ? $brew_info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
        : $brew_info =~ /i.*?(perl-\d\.\d+\.\d+)/g;
}
sub instance_remove {
    my @perls_installed = @_;

    if ($debug) {
        print "$_\n" for @perls_installed;
        print "\nremoving previous installs...\n";
    }

    my $remove_cmd = $is_win
        ? 'berrybrew remove'
        : 'perlbrew uninstall';

    for (@perls_installed){
        my $ver = $^V;
        $ver =~ s/v//;

        if ($_ =~ /$ver$/){
            print "skipping version we're using, $_\n" if $debug;
            next;
        }
        `$remove_cmd $_`;
    }

    print "\nremoval of existing perl installs complete...\n" if $debug;
}
sub instance_install {
    my $count = shift;
    my @perls_available = @_;    

    my $install_cmd = $is_win
        ? 'berrybrew install'
        : 'perlbrew install --notest -j 4';

    my @new_installs;

    if ($version){
        $version = $is_win ? $version : "perl-$version";
        push @new_installs, $version;
    }
    else {
        if ($count) {
            while ($count > 0){
                push @new_installs, $perls_available[rand @perls_available];
                $count--;
            }
        }
    }

    print "$_\n" for @new_installs;

    if (@new_installs){
        for (@new_installs){
            print "\ninstalling $_...\n" if $debug;
            `$install_cmd $_`;
        }
    }
    else {
        print "\nusing existing versions only\n" if $debug;
    }
}
sub results {

    my $exec_cmd = $is_win
        ? "berrybrew exec perl $cwd\\build\\test.pl"
        : "perlbrew exec perl $cwd/build/test.pl 2>/dev/null";

    my $debug_exec_cmd = $is_win
        ? "berrybrew exec perl $cwd\\build\\test.pl"
        : "perlbrew exec perl $cwd/build/test.pl";

    my $result;

    print "\n...executing\n" if $debug;

    if ($is_win){
        $result = `$exec_cmd`;
    }
    else {
        if ($debug){
            $result = `$debug_exec_cmd`;
        }
        else {
            $result = `$exec_cmd`;
        }
    } 

    my @ver_results = split /\n\n\n/, $result;

    print "\n\n";

    for (@ver_results){
        my $ver;

        if (/^([Pp]erl-\d\.\d+\.\d+)/){
            $ver = $1;
        }
        my $res;

        if (/Result:\s+(PASS)/){
            $res = $1; 
        }
        else {
            print $_;
            exit;
        }
        print "$ver :: $res\n";
    }
}
sub run {

    my $count = shift // 0;

    my $brew_info = $is_win
        ? `berrybrew available`
        : `perlbrew available`;
    
    my @perls_available = perls_available($brew_info);

    $count = scalar @perls_available if $count < 0;

    my @perls_installed = perls_installed($brew_info);

    print "$_\n" for @perls_installed;
    if ($debug){
        print "$_ installed\n" for @perls_installed;
        print "\n";
    }

    my %perl_vers;

    instance_remove(@perls_installed) if $reload;
    instance_install($count, @perls_available);

    results();
}
