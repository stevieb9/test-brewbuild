use warnings;
use strict;
use feature 'say';

package Re; {
    my %h = (
        re => qr/
            [Pp]erl-\d\.\d+\.\d+(?:_\w+)?
            \s+===.*?
            (?=(?:[Pp]erl-\d\.\d+\.\d+(?:_\w+)?\s+===|$))
        /xs,
        grp => qr/
            (Mock).*?(Sub)
        /xs,
    );
    sub re {
        return $h{re};
    }
    sub grp {
        return $h{grp};
    }
}

package main; {

    local $/;

    my $str = <DATA>;

    my $x = $str;
    my $y = $str;

    my $re = Re::re();

    if ($y =~ /$re/g) {
        print "returned re matches!\n";
    }

    my $grp = Re::grp();

    if ($x =~ /$grp/g){
        say "$1, $2";
    }

}

__DATA__
perl-5.26.1
==========
Reading '/home/spek/.cpan/Metadata'
  Database was generated on Tue, 13 Feb 2018 15:29:02 GMT
App::cpanminus is up to date (1.7043).
--> Working on .
Configuring /home/spek/repos/mock-sub ... OK
<== Installed dependencies for .. Finishing.
--> Working on .
Configuring /home/spek/repos/mock-sub ... Generating a Unix-style Makefile
Writing Makefile for Mock::Sub
Writing MYMETA.yml and MYMETA.json
OK
Building and testing Mock-Sub-1.10 ... Skip blib/lib/Mock/Sub.pm (unchanged)
Skip blib/lib/Mock/Sub/Child.pm (unchanged)
Manifying 2 pod documents
PERL_DL_NONLAZY=1 "/home/spek/perl5/perlbrew/perls/perl-5.26.1/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
t/00-load.t .................... ok
t/01-called.t .................. ok
t/02-called_count.t ............ ok
t/03-instantiate.t ............. ok
t/04-return_value.t ............ ok
t/05-side_effect.t ............. ok
t/06-reset.t ................... ok
t/07-name.t .................... ok
t/08-called_with.t ............. ok
t/09-void_context.t ............ ok
t/10-unmock.t .................. ok
t/11-state.t ................... ok
t/12-mocked_subs.t ............. ok
t/13-mocked_objects.t .......... ok
t/14-core_subs.t ............... ok
t/15-remock.t .................. ok
t/16-non_exist_warn.t .......... ok
t/17-no_warnings.t ............. ok
t/18-bug_25-retval_override.t .. ok
t/19-return_params.t ........... ok
t/manifest.t ................... skipped: Author tests not required for installation
t/pod-coverage.t ............... skipped: Author tests not required for installation
t/pod.t ........................ skipped: Author tests not required for installation
All tests successful.
Files=23, Tests=243,  2 wallclock secs ( 0.13 usr  0.04 sys +  1.75 cusr  0.13 csys =  2.05 CPU)
Result: PASS
OK
Successfully tested Mock-Sub-1.10

