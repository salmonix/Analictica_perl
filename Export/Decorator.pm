package Export::Decorator;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AUtils::LoadModule;
use AUtils::Filer 'read_config';

our $VERSION='';

=pod

=head1 NAME

 Export::Decorator - returns the decorator object.

=head1 DESCRIPTION

 Takes a 

=head1 METHODS

=over 4

=item - I<new( 'type',$HASH?)>

 Takes the type - eg. html -, optionally other parameters
 and returns the decorator object, passing the parameters further.

=cut 
my %modules=%{ read_config('./Export/modules.yml') };


sub new {
	my $self={};
	croak "No type is passed. " unless $_[1];
	my $type=lc $_[1];
	my $class=$modules{$type};
	return load_new_object($class,$_[2]);
}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
