use 5.006;
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
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-BrewBuild-*' },
);
