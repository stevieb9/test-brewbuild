package Test::BrewBuild::Dispatch;
use strict;
use warnings;

use Carp qw(croak);
use Cwd qw(getcwd);
use IO::Socket::INET;
use Logging::Simple;
use Parallel::ForkManager;
use Storable;
use Test::BrewBuild::Git;

our $VERSION = '1.05';

$| = 1;

my $log;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $log = Logging::Simple->new(level => 0, name => 'Dispatch');

    if (defined $args{debug}){
        $log->level($args{debug}) if defined $args{debug};
        $self->{debug} = $args{debug};
    }

    $self->{forks} = defined $args{forks} ? $args{forks} : 4;

    my $log = $log->child('new');
    $log->_5("instantiating new Test::BrewBuild::Dispatch object");

    return $self;
}
sub dispatch {
    my ($self, %params) = @_;

    my $cmd = $params{cmd};
    my $repo = $params{repo};
    my $testers = $params{testers};

    my $log = $log->child('dispatch');

    my %remotes;

    if (! $testers->[0]){
        $log->_6("no --testers passed in, attempting to read config file");

        my $conf = Config::Tiny->read( "$ENV{HOME}/.brewbuild.conf" );
        for (keys %{ $conf->{remotes} }) {
            $remotes{$_} = $conf->{remotes}{$_};
        }
        if (!$conf){
            $log->_0("no --testers and no conf file, croaking");
            croak "dispatch requires clients sent in or config file which " .
                  "isn't found\n";
        }
    }
    else {
        $log->_7("working on testers: " . join ', ', @$testers);

        for my $tester (@$testers){
            my ($host, $port);
            if ($tester =~ /:/){
                ($host, $port) = split /:/, $tester;
            }
            else {
                $host = $tester;
                $port = 7800;
            }
            $remotes{$host}{port} = $port;
            $log->_5("configured $host with port $port");
        }
    }

    # spin up the comms

    my $pm = Parallel::ForkManager->new($self->{forks});

    $pm->run_on_finish(
        sub {
            my (undef, undef, undef, undef, undef, $tester_data) = @_;
            map {$remotes{$_} = $tester_data->{$_}} keys %$tester_data;
            $log->_5("tester: " . (keys %$tester_data)[0] ." finished");
        }
    );

    CLIENTS:
    for my $tester (keys %remotes){
        $log->_7("spinning up tester: $tester");

        $pm->start and next CLIENTS;

        my %return;

        my $socket = new IO::Socket::INET (
            PeerHost => $tester,
            PeerPort => $remotes{$tester}{port},
            Proto => 'tcp',
        );
        if (! $socket){
            die "can't connect to remote $tester on port " .
                "$remotes{$tester}{port} $!\n";
        }

        $log->_7("tester $tester socket created ok");

        # syn
        $socket->send($tester);
        $log->_7("syn \"$tester\" sent");

        # ack
        my $ack;
        $socket->recv($ack, 1024);
        $log->_7("ack \"$ack\" received");

        if ($ack ne $tester){
            $log->_0("comm error: syn \"$tester\" doesn't match ack \"$ack\"");
            die "comm discrepancy: expected $tester, got $ack\n";
        }

        $socket->send($cmd);
        $log->_7("sent command: $cmd");

        my $check = '';
        $socket->recv($check, 1024);
        $log->_7("received \"$check\"");

        if ($check =~ /^error:/){
            $log->_0("received an error: $check... killing all procs");
            kill '-9', $$;
        }
        if ($check eq 'ok'){
            my $repo_link;

            if (! $repo){
                my $git = Test::BrewBuild::Git->new;
                $repo_link = $git->link;
                $log->_5("repo not sent in, set to: $repo_link via Git");
            }
            else {
                $repo_link = $repo;
                $log->_5("repo set to: $repo_link");
            }

            if (! $repo_link){
                $log->_0("repo not found, croaking");
                croak "\nno repository found, can't continue\n";
            }
            $socket->send($repo_link);
            $return{$tester}{build} = Storable::fd_retrieve($socket);
        }
        else {
            $log->_5("deleted tester: $remotes{$tester}... incomplete session");
            delete $remotes{$tester};
        }
        $socket->close();
        $pm->finish(0, \%return);
    }

    $pm->wait_all_children;

    # process the results

    if (! -d 'bblog'){
        mkdir 'bblog' or die $!;
        $log->_7("created log dir: bblog");
    }

    # init the return string

    my $return = "\n";

    for my $ip (keys %remotes){
        if (! defined $remotes{$ip}{build}){
            $log->_5("tester: $ip didn't supply results... deleting");
            delete $remotes{$ip};
            next;
        }

        # build log file generation

        for my $build_log (keys %{ $remotes{$ip}{build}{files} }){
            $log->_7("generating build log: $build_log");

            my $content = $remotes{$ip}{build}{files}{$build_log};
            $log->_7("writing out log: " . getcwd() . "/bblog/$ip\_$build_log");
            open my $wfh, '>', "bblog/$ip\_$build_log" or die $!;
            for (@$content){
                print $wfh $_;
            }
        }

        # build the return string

        my $build = $remotes{$ip}{build};

        $return .= "$ip - $build->{platform}\n";
        $return .= "$build->{log}" if $build->{log};

        if (ref $build->{data} eq 'ARRAY'){
            $return .= $_ for @{ $build->{data} };
        }
        else {
            $return .= "$build->{data}\n";
        }
    }
    $log->_7("returning results...");
    return $return;
}
1;

=head1 NAME

Test::BrewBuild::Dispatch - Dispatch C<brewbuild> testing to remote test
servers.

=head1 DESCRIPTION

This is the remote dispatching system of L<Test::BrewBuild>.

It dispatches out test runs to L<Test::BrewBuild::Tester> remote test servers
to perform, then processes the results returned from those testers.

=head1 METHODS

=head2 new

Returns a new C<Test::BrewBuild::Dispatch> object.

=head2 dispatch(cmd => '', repo => '', testers => ['', ''], debug => 0-7)

C<cmd> is the C<brewbuild> command string that will be executed.

C<repo> is the name of the repo to test against, and is optional.
If not supplied, we'll attempt to get a repo name from the local working
directory you're working in.

C<testers> is manadory unless you've set up a config file, and contains an
array reference of IP/Port pairs for remote testers to dispatch to and follow.
eg: C<[qw(10.1.1.5 172.16.5.5:9999)]>. If the port portion of the tester is
omitted, we'll default to C<7800>.

By default, the testers run on all IPs and port C<TCP/7800>.

C<debug> optional, set to a level between 0 and 7.

See L<Test::BrewBuild::Tester> for more details on the testers that the
dispatcher dispatches to.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 CONTRIBUTING

Any and all feedback and help is appreciated. A Pull Request is the preferred
method of receiving changes (L<https://github.com/stevieb9/p5-test-brewbuild>),
but regular patches through the bug tracker, or even just email discussions are
welcomed.

=head1 BUGS

L<https://github.com/stevieb9/p5-test-brewbuild/issues>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
 
