use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Xerces::DOMParse',
    'SKIP'      => [qw( test makeaperl xs_o static)],
);
