use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'XML::Invoice::Parser',
    AUTHOR           => q{Johannes Grassler <info@computer-grassler.de>},
    VERSION_FROM     => 'lib/XML/Invoice/Parser.pm',
    ABSTRACT_FROM    => 'lib/XML/Invoice/Parser.pm',
    LICENSE          => 'gpl_2',
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
      resources => {
        license     => 'https://www.gnu.org/licenses/old-licenses/gpl-2.0.html.en',
        homepage    => 'https://github.com/jgrassler/XML-Invoice-Parser',
        bugtracker  => 'https://github.com/jgrassler/XML-Invoice-Parser/issues',
        repository  => 'https://github.com/jgrassler/XML-Invoice-Parser',
      },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
				'XML::LibXML'				=> 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML::Invoice::Parser-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
