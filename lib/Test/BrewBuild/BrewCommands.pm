package Test::BrewBuild::BrewCommands;
use strict;
use warnings;

sub new {
    return bless {}, shift;
}
sub brew {
    my $self = shift;
    return $self->is_win ? 'berrybrew' : 'perlbrew';
}
sub installed {
    my ($self, $info) = @_;

    return $self->is_win
    ? $info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
    : $info =~ /i.*?(perl-\d\.\d+\.\d+)/g;
}
sub available {
    my ($self, $info) = @_;

    if ($info) {
        my @avail = $self->is_win
            ? $info =~ /(\d\.\d+\.\d+_\d+)/g
            : $info =~ /(perl-\d\.\d+\.\d+)/g;

        if ($self->is_win) {
            for (@avail) {
                s/perl-//;
            }
        }
        return @avail;
    }
    else {
        return $self->is_win
            ? `berrybrew available`
            : `perlbrew available`;
    }
}
sub install {
    my $self = shift;

    my $install_cmd = $self->is_win
        ? 'berrybrew install'
        : 'perlbrew install --notest -j 4';
}
sub remove {
    my $self = shift;

    return $self->is_win
        ? 'berrybrew remove'
        : 'perlbrew uninstall';
}
sub version {
    my ($self, $ver) = shift;

    return $self->is_win
        ? $ver
        : "perl-$ver";
}
sub is_win {
    my $is_win = ($^O =~ /Win/) ? 1 : 0;
    return $is_win;
}

1;