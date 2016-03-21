use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $is_win = $^O =~ /MSWin/ ? 1 : 0;
my $brew = $is_win ? 'berrybrew' : 'perlbrew';

if (! grep { -x "$_/$brew"}split /:/,$ENV{PATH}){
    if ($is_win){
        warn "\n'berrybrew' can't be found; we'll install the module, but won't test...\n\n" .
             "You can fetch and install 'Berrybrew' here: " .
             "https://github.com/dnmfarrell/berrybrew\n\n";
    }
    else {
        warn "\n'perlbrew' can't be found, we'll install the module, but won't test...\n\n" .
             "Go to http://perlbrew.pl for installation info\n\n";
    }

    sleep 3;
}
WriteMakefile(
    NAME             => 'Test::BrewBuild',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Test/BrewBuild.pm',
    ABSTRACT_FROM    => 'lib/Test/BrewBuild.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    EXE_FILES        => [ map "bin/$_", qw(brewbuild) ],
    MIN_PERL_VERSION => 5.008,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/p5-test-brewbuild/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/p5-test-brewbuild.git',
                web => 'https://github.com/stevieb9/p5-test-brewbuild',
            },
        },
    },
    PREREQ_PM => {
        'App::cpanminus' => 0,
        'Logging::Simple' => '0.07',
        'Module::Load'  => 0,   # corelist since 5.9.4
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-BrewBuild-*' },
);

