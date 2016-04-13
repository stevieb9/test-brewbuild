package Test::BrewBuild::Dispatch;
use strict;
use warnings;

use Carp qw(croak);
use IO::Socket::INET;
use Parallel::ForkManager;
use Storable;

our $VERSION = '1.05';

$| = 1;

sub new {
    my $class = shift;
    my $log = shift;
    my $self = bless {log => $log}, $class;
    return $self;
}
sub dispatch {
    my ($self, $cmd, $repo, $params) = @_;

    #my $log = $self->{log}->child('Dispatch::dispatch');
    my %remotes;

    if (!$params->[0]) {
        my $conf = Config::Tiny->read( "$ENV{HOME}/.brewbuild.conf" );
        for (keys %{ $conf->{remotes} }) {
            $remotes{$_} = $conf->{remotes}{$_};
        }
        if (!$conf) {
            croak "dispatch requires clients sent in or config file which " .
                  "isn't found\n";
        }
    }
    else {
        for (@$params) {
            $remotes{(split /:/, $_)[0]}{port} = (split /:/, $_)[1];
        }
    }

    # spin up the comms

    my $pm = Parallel::ForkManager->new(4);

    $pm->run_on_finish(
        sub {
            my (undef, undef, undef, undef, undef, $tester_data) = @_;
            map {$remotes{$_} = $tester_data->{$_}} keys %$tester_data;
        }

    );

    CLIENTS:
    for my $tester (keys %remotes){
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

        # syn
        $socket->send($tester);

        # ack
        my $ack;
        $socket->recv($ack, 1024);

        die "comm discrepancy: expected $tester, got $ack\n" if $ack ne $tester;

        $socket->send($cmd);

        my $ok = '';
        $socket->recv($ok, 1024);

        if ($ok eq 'ok'){
            $socket->send($repo);
            $return{$tester}{build} = Storable::fd_retrieve($socket);
        }
        else {
            delete $remotes{$tester};
        }
        $socket->close();
        $pm->finish(0, \%return);
    }

    $pm->wait_all_children;

    # process the results

    mkdir 'bblog' if ! -d 'bblog';
    print "\n";

    for my $ip (keys %remotes){
        if (! defined $remotes{$ip}{build}){
            delete $remotes{$ip};
            next;
        }
        # FAIL file generation

        for my $fail_file (keys %{ $remotes{$ip}{build}{files} }){
            my $content = $remotes{$ip}{build}{files}{$fail_file};
            open my $wfh, '>', "bblog/$ip\_v$fail_file" or die $!;
            for (@$content){
                print $wfh $_;
            }
        }

        # dump out the info

        my $build = $remotes{$ip}{build};

        print "$ip - $build->{platform}\n";

        if (ref $build->{data} eq 'ARRAY'){
            print $_ for @{ $build->{data} };
        }
        else {
            print "$build->{data}\n";

        }

    }
}
1;

=head1 NAME

Test::BrewBuild::Dispatch - Dispatch C<brewbuild> testing to remote test
servers.

=head1 DESCRIPTION

This is the helper module for the remote dispatching system of
L<Test::BrewBuild>, and shouldn't be used directly.

It dispatches out test runs for remote test servers to perform, then processes
the results returned from those testers.

=head1 METHODS

=head2 new

Returns a new Test::BrewBuild::Dispatch object.

=head2 dispatch($cmd, $repo, $params)

C<$cmd> is the C<brewbuild> command string that will be executed.

C<$repo> is the git repository to base the testing on.

C<$params> is optional, and contains an array reference of IP/Port pairs for
remote testers to dispatch to and follow. eg: C<10.1.1.5:7800>.

By default, the testers run on all IPs and port TCP/7800.

See L<Test::BrewBuild::Tester>.

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
 
