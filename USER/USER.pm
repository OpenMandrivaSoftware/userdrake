package USER;

use strict;
require DynaLoader;

our @ISA = qw(DynaLoader);
our $VERSION = '0.92';

USER->bootstrap($VERSION);

# Preloaded methods go here.

package USER::ADMIN;
our @ISA = qw();

package USER::ENT;
our @ISA = qw();

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

USER - Perl extension for libuser API 

=head1 SYNOPSIS

  use USER;
  
=head1 ABSTRACT

  A user and group account administration library
  
=head1 DESCRIPTION

  The libuser library implements a standardized interface for manipulating
  and administering user and group accounts.  The library uses pluggable
  back-ends to interface to its data sources.
  This is the perl Extension for libuser. It is mostly used by userdrake 
  which is a GUI for user and groups administration 

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Daouda LO, E<lt>daouda@mandrakesoft.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mandrakesoft SA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
