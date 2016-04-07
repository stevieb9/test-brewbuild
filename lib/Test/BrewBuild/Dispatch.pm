package Test::BrewBuild::Dispatch;
use strict;
use warnings;

use Carp qw(croak);
use Config;
use Data::Dumper;
use File::Temp;
use IO::Socket::INET;
use Storable;

our $VERSION = '1.05';

$| = 1;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}
sub dispatch {
    my ($self, $cmd, $repo, $params) = @_;

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

    for my $client (keys %remotes){
        my $socket = new IO::Socket::INET (
            PeerHost => $client,
            PeerPort => $remotes{$client}{port},
            Proto => 'tcp',
        );
        warn "can't connect to remote $client on port $remotes{$client} $!\n"
          unless $socket;

        $socket->send($cmd);

        my $ok = '';
        $socket->recv($ok, 1024000);

        if ($ok eq 'ok'){
            $socket->send($repo);
            $remotes{$client}{build} = Storable::fd_retrieve($socket);
        }
        else {
            delete $remotes{$client};
            $socket->close();
        }
    }

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

        my $client = $sock->accept;

        my $cmd;
        $client->recv($cmd, 1024);

        $client->send('ok');

        my $repo = '';
        $client->recv($repo, 1024);

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
            Storable::nstore_fd($res, $client);
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
 
