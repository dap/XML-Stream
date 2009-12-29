use 5.008_000;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'  => 'XML::Stream',
    'VERSION_FROM' => 'lib/XML/Stream.pm',
    'PREREQ_PM' => {
        'Authen::SASL' => 0,
        'MIME::Base64' => 0,
    },
    'dist' => {
        'COMPRESS' => 'gzip --best'
    }
);

