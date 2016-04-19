package Test::BrewBuild::Tester;
use strict;
use warnings;

use Carp qw(croak);
use Config;
use Cwd qw(getcwd);
use File::Path qw(remove_tree);
use IO::Socket::INET;
use Logging::Simple;
use Proc::Background;
use Storable;
use Test::BrewBuild;
use Test::BrewBuild::Git;

our $VERSION = '1.05';

$| = 1;

my $log;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    my $log_to_stdout = defined $args{stdout} ? $args{stdout} : 0;

    $log = Logging::Simple->new(level => 0, name => 'Tester');
    $log->file(\$self->{log}) if ! $log_to_stdout;

    if (defined $args{debug}){
        $log->level($args{debug}) if defined $args{debug};
        $self->{debug} = $args{debug};
    }

    my $log = $log->child('new');
    $log->_5("instantiating new Test::BrewBuild::Tester object");

    $self->_config;
    $self->_pid_file;

    return $self;
}
sub start {
    my $self = shift;

    my $log = $log->child("start");
    my $pid_file = $self->_pid_file;

    if ($self->status){
        my $fh;
        open $fh, '<', $pid_file or die $!;
        my $existing_pid = <$fh>;
        close $fh;

        if ($existing_pid){
            if (kill(0, $existing_pid)){
                $log->_0("tester is already running at PID $existing_pid");
                die "\nTest::BrewBuild test server already running " .
                    "on PID $existing_pid...\n\n";
            }
        }
    }

    my ($perl, @args, $work_dir);

    if ($^O =~ /MSWin/){
        $work_dir = "$ENV{HOMEPATH}/brewbuild";

        $log->_6("on Windows, using work dir $work_dir");

        $perl = (split /\n/, `where perl.exe`)[0];
        my $t = (split /\n/, `where bbtester`)[0];

        $log->_6("using command: $perl $t --fg");

        @args = ($t, '--fg');
    }
    else {
        $work_dir = "$ENV{HOME}/brewbuild";

        $log->_6("on Unix, using work dir $work_dir");

        $perl = 'perl';
        @args = qw(bbtester --fg);

        $log->_6("using command: bbtester --fg");
    }

    if (defined $self->{debug}){
        push @args, ('--debug', $self->{debug});
    }

    mkdir $work_dir or die "can't create $work_dir dir: $!" if ! -d $work_dir;
    chdir $work_dir or die "can't change to dir $work_dir: $!";
    $log->_7("chdir to: ".getcwd());

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

    $log->_5("Started the BB test server at PID $pid on IP $ip and port $port");

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
                $log->_0("error! run bbtester --fg at the CLI and check for " .
                         "failure"
                );
                die "\nerror! run bbtester --fg at the command line and " .
                    "check for failure\n\n";
            }
        }
    }
}
sub stop {
    my $self = shift;

    my $log = $log->child("stop");

    $log->_5("attempting to stop the tester service");

    if (! $self->status) {
        $log->_5("Test::BrewBuild test server is not running");
        print "\nTest::BrewBuild test server is not running...\n\n";
        return;
    }

    my $pid_file = $self->_pid_file;

    open my $fh, '<', $pid_file or die $!;
    my $pid = <$fh>;
    close $fh;
    $log->_5("Stopping the BB test server at PID $pid");
    print "\nStopping the Test::BrewBuild test server at PID $pid...\n\n";
    kill 'KILL', $pid;
    unlink $pid_file;
}
sub status {
    my $self = shift;
    my $log = $log->child("status");
    my $pid_file = $self->_pid_file;
    my $status = -f $pid_file ? 1 : 0;
    $log->_6("test server status: $status");
    return $status;
}
sub listen {
    my $self = shift;
    my $log = $log->child("listen");

    my $sock = new IO::Socket::INET (
        LocalHost => $self->ip,
        LocalPort => $self->port,
        Proto => 'tcp',
        Listen => 5,
        Reuse => 1,
    );
    die "cannot create socket $!\n" unless $sock;

    $log->_6("successfully created network socket on IP $self->{ip} and port " .
             "$self->{port}"
    );

    # working dir

    my $work_dir;

    if ($^O =~ /MSWin/){
        $work_dir = "$ENV{HOMEPATH}/brewbuild";
        mkdir $work_dir if ! -d $work_dir;
        chdir $work_dir;
        $log->_7("on Windows, work dir is: $work_dir");
        $log->_7("chdir to work dir: ".getcwd());
    }
    else {
        $work_dir = "$ENV{HOME}/brewbuild";
        mkdir $work_dir if ! -d $work_dir;
        chdir $work_dir;
        $log->_7("on Windows, work dir is: $work_dir");
        $log->_7("chdir to work dir: ".getcwd());
    }

    while (1){

        my $res = {
            platform => $Config{archname},
        };

        $log->_7("platform: $res->{platform}");

        my $dispatch = $sock->accept;

        $log->_7("now accepting incoming connections");

        # ack
        my $ack;
        $dispatch->recv($ack, 1024);

        $log->_7("received ack: $ack");

        $dispatch->send($ack);

        $log->_7("returned ack: $ack");

        my $cmd;
        $dispatch->recv($cmd, 1024);
        $res->{cmd} = $cmd;

        $log->_7("received cmd: $res->{cmd}");

        my @args = split /\s+/, $cmd;

        if ($args[0] ne 'brewbuild'){
            my $err = "error: only 'brewbuild' is allowed as a command\n\n";
            $log->_0($err);
            $dispatch->send($err);
            next;
        }
        else{
            shift @args;
            $log->_7("sending 'ok'");
            $dispatch->send('ok');
        }

        my $repo = '';
        $dispatch->recv($repo, 1024);
        $res->{repo} = $repo;

        $log->_7("received repo: $repo");

        if ($repo){
            my $git = Test::BrewBuild::Git->new;

            if (-d $git->name($repo)){
                $log->_7("repo '".$git->name($repo)."' exists, pulling");
                chdir $git->name($repo) or die $!;
                $log->_7("chdir to: ".getcwd());
                $git->pull;
            }
            else {
                $git->clone($repo);
                $log->_7("repo doesn't exist... cloning");
                chdir $git->name($repo);
                $log->_7("chdir to: ".getcwd());
            }
            {
                my %opts = Test::BrewBuild->options(\@args);
                my $opt_str;
                for (keys %opts){
                    $opt_str .= "$_ => $opts{$_}\n" if defined $opts{$_};
                }
                $log->_5("commencing test run with args: $opt_str") if $opt_str;

                my $bb = Test::BrewBuild->new(%opts);
                $bb->instance_remove if $opts{remove};
                $bb->instance_install($opts{install}) if $opts{install};

                if ($opts{notest}){
                    $log->_5("no tests run due to --notest flag set");
                    $log->_5("storing and sending results back to dispatcher");
                    $res->{log} = $self->{log};
                    Storable::nstore_fd($res, $dispatch);
                    next;
                }
                if ($opts{revdep}){
                    $res->{data} = $bb->revdep(%opts);
                }
                else {
                    $res->{data} = $bb->test;
                }
            }

            if (-d 'bblog'){
                chdir 'bblog';
                $log->_7("chdir to: ".getcwd());
                my @entries = glob '*';
                $log->_5("log files: " . join ', ', @entries);
                for (@entries){
                    $log->_7("processing log file: " .getcwd() ."/$_");
                    next if ! -f || ! /\.bblog/;
                    open my $fh, '<', $_ or die $!;
                    @{ $res->{files}{$_} } = <$fh>;
                    close $fh;
                }
                chdir '..';
                $log->_7("chdir to: ".getcwd());

                $log->_7("removing log dir: " . getcwd() . "/bblog");
                remove_tree 'bblog' or die $!;
            }
            $log->_5("storing and sending results back to dispatcher");
            $res->{log} = $self->{log};

            Storable::nstore_fd($res, $dispatch);
            chdir '..';
        }
    }
    $sock->close();
}
sub ip {
    my ($self, $ip) = @_;

    return $self->{ip} if $self->{ip};

    if (! $ip && $self->{conf}{ip}){
        $ip = $self->{conf}{ip};
    }
    $ip = '0.0.0.0' if ! $ip;
    $self->{ip} = $ip;
}
sub port {
    my ($self, $port) = @_;

    return $self->{port} if $self->{port};

    if (! $port && $self->{conf}{port}){
        $port = $self->{conf}{port};
    }
    $port = '7800' if ! defined $port;
    $self->{port} = $port;
}
sub _config {
    my $self = shift;

    my $conf_file = Test::BrewBuild->config_file;

    if (-f $conf_file){
        my $conf = Config::Tiny->read($conf_file)->{tester};
        $self->{conf}{ip} = $conf->{ip};
        $self->{conf}{port} = $conf->{port};
    }
}
sub _pid_file {
    my $self = shift;

    return $self->{pid_file} if defined $self->{pid_file};

    $self->{pid_file} = $^O =~ /MSWin/
        ? "$ENV{HOMEPATH}/brewbuild/brewbuild.pid"
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
 
