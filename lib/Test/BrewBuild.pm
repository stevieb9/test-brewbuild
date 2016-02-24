package Test::BrewBuild;

use 5.006;
use strict;
use warnings;

use File::Temp;

our $VERSION = '0.02';

sub new {

    my ($class, %args) = @_;
    my $self = bless {}, $class;
    %{ $self->{args} } = %args;
    return $self;
}
sub perls_available {
    my ($self, $brew_info) = @_;

    my @perls_available = $self->is_win
        ? $brew_info =~ /(\d\.\d+\.\d+_\d+)/g
        : $brew_info =~ /(perl-\d\.\d+\.\d+)/g;

    if ($self->is_win){
        for (@perls_available){
            s/perl-//;
        }
    }
    return @perls_available;
}
sub perls_installed {
    my ($self, $brew_info) = @_;

    return $self->is_win
        ? $brew_info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
        : $brew_info =~ /i.*?(perl-\d\.\d+\.\d+)/g;
}
sub instance_remove {
    my ($self, @perls_installed) = @_;

    if ($self->{args}{debug}) {
        print "$_\n" for @perls_installed;
        print "\nremoving previous installs...\n";
    }

    my $remove_cmd = $self->is_win
        ? 'berrybrew remove'
        : 'perlbrew uninstall';

    for (@perls_installed){
        my $ver = $^V;
        $ver =~ s/v//;

        if ($_ =~ /$ver$/){
            print "skipping version we're using, $_\n" if $self->{args}{debug};
            next;
        }
        `$remove_cmd $_`;
    }

    print "\nremoval of existing perl installs complete...\n" if $self->{args}{debug};
}
sub instance_install {
    my $self = shift;
    my $count = shift;
    my @perls_available = @_;

    my $install_cmd = $self->is_win
        ? 'berrybrew install'
        : 'perlbrew install --notest -j 4';

    my @new_installs;

    if ($self->{args}{version}){
        $self->{args}{version} = $self->is_win
            ? $self->{args}{version}
            : "perl-$self->{args}{version}";

        push @new_installs, $self->{args}{version};
    }
    else {
        if ($count) {
            while ($count > 0){
                push @new_installs, $perls_available[rand @perls_available];
                $count--;
            }
        }
    }

    if ($self->{args}{debug}){
        print "$_\n" for @new_installs;
    }

    if (@new_installs){
        for (@new_installs){
            print "\ninstalling $_...\n" if $self->{args}{debug};
            `$install_cmd $_`;
        }
    }
    else {
        print "\nusing existing versions only\n" if $self->{args}{debug};
    }
}
sub results {
    my $self = shift;

    my $test = $self->_test_file;

    my $exec_cmd = $self->is_win
        ? "berrybrew exec perl $test"
        : "perlbrew exec perl $test 2>/dev/null";

    my $debug_exec_cmd = $self->is_win
        ? "berrybrew exec perl $test"
        : "perlbrew exec perl $test";

    my $result;

    print "\n...executing\n" if $self->{args}{debug};

    if ($self->is_win){
        $result = `$exec_cmd`;
    }
    else {
        if ($self->{args}{debug}){
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
    my $self = shift;
    my $count = shift // 0;

    my $brew_info = $self->is_win
        ? `berrybrew available`
        : `perlbrew available`;

    my @perls_available = $self->perls_available($brew_info);

    $count = scalar @perls_available if $count < 0;

    my @perls_installed = $self->perls_installed($brew_info);

    if ($self->{args}{debug}){
        print "$_ installed\n" for @perls_installed;
        print "\n";
    }

    $self->instance_remove(@perls_installed) if $self->{args}{reload};
    $self->instance_install($count, @perls_available);

    $self->results();
}
sub is_win {
    return $^O =~ /Win/ ? 1 : 0;
}
sub _test_file {
    my $self = shift;

    my $test = File::Temp->new(UNLINK => 1, SUFFIX => '.pl');

    my $cmd = $self->is_win
        ? 'system "cpanm --installdeps . && dmake && dmake test"'
        : 'system "cpanm --installdeps . && make && make test"';

    print $test $cmd;

    return $test;
}
1;

=head1 NAME

Test::BrewBuild - Cross-platform unit testing automation across numerous perl
versions.

=head1 SYNOPSIS

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-brewbuild at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-BrewBuild>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::BrewBuild


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Test::BrewBuild
