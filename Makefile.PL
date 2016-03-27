use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $is_win = $^O =~ /MSWin/ ? 1 : 0;
my $brew = $is_win ? 'berrybrew.exe' : 'perlbrew';
my $brew_link = $is_win 
    ? 'https://github.com/dnmfarrell/berrybrew'
    : 'http://perlbrew.pl';
my $sep = $is_win ? ';' : ':';

if (! grep { -x "$_/$brew" } split /$sep/, $ENV{PATH}){
        warn "\n$brew can't be found; we'll install this module, but " .
             "the 'brewbuild' command won't work\n\n" .
             "You can fetch and install '$brew' here: $brew_link\n\n";
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
    BUILD_REQUIRES => {
        'Mock::Sub' => '1.06',
    },
    PREREQ_PM => {
        'App::cpanminus' => 0,
        'Archive::Extract' => 0,
        'CPAN::ReverseDependencies' => 0,
        'Logging::Simple' => '0.07',
        'Module::Load' => 0,   # corelist since 5.9.4
        'Plugin::Simple' => '0.06',
        'Test::BrewBuild::Plugin::TestAgainst' => '0.03',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-BrewBuild-*' },
);

