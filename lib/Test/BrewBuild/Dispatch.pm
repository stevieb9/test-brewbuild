package Test::BrewBuild::Dispatch;
use strict;
use warnings;

use Carp qw(croak);
use Config;
use Data::Dumper;
use File::Temp;
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
            croak "dispatch requires clients sent in or config file which isn't found";
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
        warn "can't connect to remote $tester on port $remotes{$tester} $!\n"
          unless $socket;

        # syn
        $socket->send($tester);

        # ack
        my $ack;
        $socket->recv($ack, 1024);

        die "comms issue\n" if ! $ack eq $tester;

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

        print "$ip - $build->{platform}\n" .
              "$build->{data}\n";
    }
}
sub listen {
    my ($self) = @_;
    #my $log = $self->{log}->child('Dispatch::listen');

    my $ip = '0.0.0.0';
    my $port = '7800';

    my $sock = new IO::Socket::INET (
        LocalHost => $ip,
        LocalPort => $port,
        Proto => 'tcp',
        Listen => 5,
        Reuse => 1,
    );
    die "cannot create socket $!\n" unless $sock;

    while (1){

        my $res = {
            platform => $Config{archname},
        };

        my $dispatch = $sock->accept;

        # ack
        my $ack;
        $dispatch->recv($ack, 1024);

        $dispatch->send($ack);

        my $cmd;
        $dispatch->recv($cmd, 1024);
        $dispatch->send('ok');

        my $repo = '';
        $dispatch->recv($repo, 1024);

        $res->{repo} = $repo;
        $res->{cmd} = $cmd;

        if ($cmd && $repo){
            my $repo_dir = $self->_clone_repo($repo);
            chdir $repo_dir;
            $res->{data} = `$cmd`;
            if (-d 'bblog'){
                chdir 'bblog';
                my @entries = glob '*';
                for (@entries){
                    next if ! -f || ! /\.bblog/;
                    open my $fh, '<', $_ or die $!;
                    @{ $res->{files}{$_} } = <$fh>;
                    close $fh;
                }
                chdir '..';
            }
            Storable::nstore_fd($res, $dispatch);
            chdir '..';
        }
    }
    $sock->close();
}
sub _clone_repo {
    my ($self, $repo) = @_;

    my $sep = $^O =~ /MSWin/ ? ';' : ':';
    my $git = $^O =~ /MSWin/ ? 'git.exe' : 'git';

    if (!grep { -x "$_/$git"} split /$sep/, $ENV{PATH}) {
        croak "$git not found\n";
    }

    if ($repo =~ m!.*/(.*?)(?:\.git)*$!){
        if (! -d $1){
            my $clone_ok = system("git clone $repo");
        }
        else {
            chdir $1;
            system("git pull");
            chdir '..';
        }
        return $1;
    }
}
1;

=head1 NAME

Test::BrewBuild::Dispatch - Provides dispatching/listening services for
Test::Brewbuild

=head1 METHODS

=head2 new

Returns a new Test::BrewBuild::BrewCommands object.

=head2 brew

Returns 'perlbrew' if on Unix, and 'berrybrew' if on Windows.

=head2 info

Returns the string result of *brew available.

=head2 installed($info)

Takes the output of '*brew available' in a string form. Returns the currently
installed versions, formatted in a platform specific manner.

=head2 available($legacy, $info)

Similar to C<installed()>, but returns all perls available.

=head2 using($info)

Returns the current version of perl we're using.

=head2 install

Returns the current OS's specific *brew install command.

=head2 remove

Returns the current OS's specific *brew remove command.

=head2 is_win

Returns 0 if on Unix, and 1 if on Windows.

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
 
