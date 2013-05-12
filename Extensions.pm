package Extensions;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AUtils::LoadModule;
use AUtils::Filer 'read_config';

our $VERSION='';

=pod

=head1 NAME

 Extensions - get extensions 'Factory'.

=head1 DESCRIPTION

 Initializes the chosen module. The module must do its own sanity checks at
 installation or startup. If the module has any problem during initialisation,
 it should return undef and set $Extensions::err to some value.
 The modules are stored in a yamled HASH in the following format:

 type => { name1  => module_name,
           name2  => module_name,
	   }

 Eg. 
 
 stemmer => { hunspell => 'Text::Hunspell' }

=head1 METHODS

=over 4

=item - I<new( $HASH )>

 Initializes and returns the requested module. The HASH has the following keys:
 type       
 module_name 
 parameters

 Eg. { type => 'stemmer', module_name=>'hunspell',parameters=>\@params }

 The parameters are passed straight to the requested module. 

=cut 

my $modules='./Extensions/modules.yml';
#my %modules=%{ read_config($modules) };

my %modules=(
	stemmer=> {
		hunspell=>'Extensions::Stemmer::Hunspell',
	},
	tokenizer=> {
		default=>'Extensions::Tokenizer::default',
	},
);



our $err=undef;

sub new {
	my (undef,$param)=@_;
	$param->{module_name}||='default';
	my $extension=$modules{ $param->{type}}{ $param->{module_name} } || return undef;
	unless ( load_module( $extension  )) {
			if ( $err ) {
				carp $err;
				$err=undef;
			}
			return undef;
		}
	return $extension->new($param->{parameters});
	
}

=item - I<Extensions->get_module_list>

 Returns the actual module HASH.

=cut

sub get_module_list {
	return \%modules;
}

# for later
sub refresh_list {
	%modules=%{ read_config($modules) };
}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
