use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'whatbot',
    AUTHOR              => q{Nicholas Melnick <nick@abstractwankery.com>},
    VERSION_FROM        => 'lib/whatbot.pm',
    ABSTRACT_FROM       => 'lib/whatbot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'Moose'             => 0,
        'MooseX::Declare'   => 0,
        'Class::Load'       => 0,
        'Module::Pluggable' => 0,
        'XML::Simple'       => 0,
        'Class::Inspector'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'whatbot-*' },
);
