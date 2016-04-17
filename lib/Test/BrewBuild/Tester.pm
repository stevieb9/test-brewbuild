package Test::BrewBuild::Tester;
use strict;
use warnings;

use Capture::Tiny qw(:all);
use Carp qw(croak);
use Config;
use IO::Socket::INET;
use Proc::Background;
use Storable;
use Test::BrewBuild;
use Test::BrewBuild::Git;

our $VERSION = '1.05';

$| = 1;

sub new {
    my $class = shift;
    my $log = shift;
    my $self = bless {}, $class;
    $self->{log} = $log;
    $self->_pid_file;
    return $self;
}
sub start {
    my $self = shift;

    my $pid_file = $self->_pid_file;

    if ($self->status){
        my $fh;
        open $fh, '<', $pid_file or die $!;
        my $existing_pid = <$fh>;
        close $fh;

        if ($existing_pid){
            if (kill(0, $existing_pid)){
                die "\nTest::BrewBuild test server already running " .
                    "on PID $existing_pid...\n\n";
            }
        }
    }

    my ($perl, @args, $work_dir);

    if ($^O =~ /MSWin/){
        $work_dir = 'c:/brewbuild';

        $perl = (split /\n/, `where perl.exe`)[0];
        my $brew = (split /\n/, `where bbtester`)[0];

        @args = ($brew, '--fg');
    }
    else {
        $work_dir = "$ENV{HOME}/brewbuild";

        $perl = 'perl';
        @args = qw(bbtester --fg);
    }

    mkdir $work_dir or die "can't create $work_dir dir: $!" if ! -d $work_dir;
    chdir $work_dir or die "can't change to dir $work_dir: $!";

    my $bg;

    if ($^O =~ /MSWin/){
        $bg = Proc::Background->new($perl, @args);
    }
    else {
        $bg = Proc::Background->new(@args);
    }

    my $pid = $bg->pid;

    my $ip = $self->ip;
    my $port = $self->port;

    print "\nStarted the Test::BrewBuild test server at PID $pid on IP " .
      "address $ip and TCP port $port...\n\n";

    open my $wfh, '>', $pid_file or die $!;
    print $wfh $pid;
    close $wfh;

    # error check for bbtester

    if ($self->status){
        sleep 1;
        my $fh;
        open $fh, '<', $pid_file or die $!;
        my $existing_pid = <$fh>;
        close $fh;

        if ($existing_pid){
            if (! kill(0, $existing_pid)){
                die "\nerror! run bbtester --fg at the command line and " .
                    "check for failure\n\n";
            }
        }
    }
}
sub stop {
    my $self = shift;

    if (! $self->status) {
        print "\nTest::BrewBuild test server is not running...\n\n";
        return;
    }

    my $pid_file = $self->_pid_file;

    open my $fh, '<', $pid_file or die $!;
    my $pid = <$fh>;
    close $fh;
    print "\nStopping the Test::BrewBuild test server at PID $pid...\n\n";
    kill 'KILL', $pid;
    unlink $pid_file;
}
sub status {
    my $self = shift;
    my $pid_file = $self->_pid_file;
    my $status = -f $pid_file ? 1 : 0;
    return $status;
}
sub listen {
    my $self = shift;
    my $log = $self->{log};

    my $sock = new IO::Socket::INET (
        LocalHost => $self->ip,
        LocalPort => $self->port,
        Proto => 'tcp',
        Listen => 5,
        Reuse => 1,
    );
    die "cannot create socket $!\n" unless $sock;

    # working dir

    if ($^O =~ /MSWin/){
        mkdir "c:/brewbuild" if ! -d "c:/brewbuild";
        chdir "c:/brewbuild";
    }
    else {
        mkdir "$ENV{HOME}/brewbuild" if ! -d "$ENV{HOME}/brewbuild";
        chdir "$ENV{HOME}/brewbuild";
    }

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
        $res->{cmd} = $cmd;

        my @args = split /\s+/, $cmd;

        if ($args[0] ne 'brewbuild'){
            my $err = "error: only brewbuild is allowed as a command\n\n";
            $dispatch->send($err);
            next;
        }
        else{
            shift @args;
            $dispatch->send('ok');
        }

        my $repo = '';
        $dispatch->recv($repo, 1024);
        $res->{repo} = $repo;

        if ($repo){
            my $git = Test::BrewBuild::Git->new;

            if (-d $git->name($repo)){
                chdir $git->name($repo) or die $!;
                $git->pull;
            }
            else {
                $git->clone($repo);
                chdir $git->name($repo);
            }
            {
                my %opts = Test::BrewBuild->options(\@args);
                my $bb = Test::BrewBuild->new(%opts);
                $bb->instance_remove if $opts{remove};
                $bb->instance_install($opts{install}) if $opts{install};
                $res->{data} = $bb->revdep(%opts);
            }

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
sub ip {
    my ($self, $ip) = @_;
    return $self->{ip} if $self->{ip};
    $ip = '0.0.0.0' if ! $ip;
    $self->{ip} = $ip;
}
sub port {
    my ($self, $port) = @_;
    return $self->{port} if $self->{port};
    $port = '7800' if ! defined $port;
    $self->{port} = $port;
}
sub _pid_file {
    my $self = shift;

    return $self->{pid_file} if defined $self->{pid_file};

    $self->{pid_file} = $^O =~ /MSWin/
        ? 'c:/brewbuild/brewbuild.pid'
        : "$ENV{HOME}/brewbuild/brewbuild.pid";
}
1;

=head1 NAME

Test::BrewBuild::Tester - Daemonized testing service for dispatched test run
execution, for Windows & Unix.

=head1 DESCRIPTION

Builds and puts into the background a L<Test::BrewBuild> remote tester
listening service.

=head1 METHODS

=head2 new

Returns a new C<Test::BrewBuild::Tester> object.

=head2 start

Starts the tester, and puts it into the background.

=head2 stop

Stops the tester and all of its processes.

=head2 status

Returns 1 if there's a tester currently running, and 0 if not.

=head2 ip($ip)

Default listening IP address is C<0.0.0.0> ie. all currently bound IPs. Send in
an alternate IP address to listen on a specific one.

Returns the currently used IP.

=head2 port($port)

Default port is C<7800>. Send in an alternate to listen on it instead.

Returns the port currently being used.

=head2 listen

This is the actual service that listens for and processes requests.

By default, listens on all IP addresses bound to all network interfaces, on
port C<7800>.

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
 
