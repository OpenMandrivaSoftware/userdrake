use ExtUtils::MakeMaker;
$Verbose=1;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $libs = "" . `pkg-config --libs libuser`;
chomp $libs;
$libs .= "-lpam_misc -lpam ";
WriteMakefile(
    'NAME'		=> 'USER',
    'OPTIMIZE'		=> '-Wno-declaration-after-statement',
    'VERSION_FROM'	=> 'USER.pm',
    'OBJECT'		=> 'USER.o', # link all the C files too
    'LIBS'		=> "$libs", # e.g., '-lm'
    'DEFINE'		=> '-DPACKAGE_NAME=\"userdrake\"', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> "`pkg-config --cflags libuser`", # e.g., '-I. -I/usr/include/other'
    'XSPROTOARG'        => '-noprototypes',
    'TYPEMAPS'  => ['../perlobject.map' ],
);
