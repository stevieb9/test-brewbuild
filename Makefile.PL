use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

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
