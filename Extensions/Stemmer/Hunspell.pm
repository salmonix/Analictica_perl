package Extensions::Stemmer::Hunspell;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AUtils::LoadModule;
use AUtils::Filer qw(read_config);

our $VERSION='';

=pod

=head1 NAME

 Extensions::Stemmer::Sunspell - Wrapper for Text::Hunspell.

=head1 DESCRIPTION

 The module stores its data in the Hunspell.yml file. The file is a yamled HASH,
 as
 
 lang=> 'lang' , 
 files=>[ path_do_dic, path_to_aff ] 
 
 The object is an ARRAY, where [0] is the stemmer object.

=head1 METHODS

=over 4

=item - I<new( HASH? )>

 Parameters are optional, same as at set_stemmer.
 
=cut 
my %config;
my $confpath='../Extensions/Stemmer/Hunspell.yml';
eval { %config= %{ read_config( $confpath ) } };
our ($puff,$string);

sub new {
	my (undef,$params)=@_;
	my $self=[];
	bless $self,__PACKAGE__;
	$self->set_stemmer($params) if $params;
	return $self;
}

=item - I<set_module({ lang=> 'lang' , files=>[ path_do_dic, path_to_aff ]}  )>

 Initializes the stemmer. Takes a HASH, where the only mandatory 
 parameter is the 'lang' parameter. If no files is passed, 
 it reads the Hunspell.yml config file in the ../Extensions/Stemmer/ file 
 and tries to use those.

=cut 

sub set_module {
	my ($self,$params)=@_;
	if ( !$params->{lang} ) {
		$Extensions::err="USAGE: Enxtensions::Stemmer::Hunspell->new({ lang=>'lang' }) is mandatory.";
		return undef;
	}
	if ( !$params->{files} ) {
		$params->{files}=$config{ $params->{lang} }{files};
		if ( !$params->{files} ) {
			$Extensions::err="No such lang '$params->{lang}' is configured for ".__PACKAGE__;
			return undef;
		}
	}
	$self->[0]=load_new_object('Text::Hunspell',@{$params->{files}});
	if ( !$self->[0] ) {
		$Extensions::err="Problem initializing Text::Hunspell";
		return undef;
	}
}

=item - I<stem('string'|$token)>

 Stems the token names - skipping sigilled containers - calling ->stem of Hunspell.
 Returns undef on not foung.

=cut

sub stem {
        (ref $_[1])?$string=$_[1]->{name}:$string=pop;
	return $_[0]->[0]->stem($string);
}

=item - I<base($token)>

 Returns the base of the word calling ->analyze and picking the st: element.
 The difference may mean that stem returns a prefixed form of the word, base returns
 the base form. Eg. Hungarian 'megfogta' /verb: 'he/she caught (that)' / has the stem
 'megfog', and a base 'fog' /meaning 'hold, grasp'/ without the 'meg' prefix, which adds 
 a punctual/perfecta aspect to the base.
 Returns undef on not found.
 NOTE: The return values of these - esp. base - functions may differ as .dic and .aff 
 files may differ.

=cut

sub base {
        (ref $_[1])?$string=$_[1]->{name}:$string=pop;
	$puff=$_[0]->[0]->analyze( $string );
	if ($puff) {
		($puff)=($puff=~/.*?\sst:(.*?)\s/);
		return $puff;
	};
	return undef;
}

=item - I<languages>

 Returns the languages configured for the stemmer.

=cut

sub languages {
	return keys %config;
}		

=item - I<add_lang({ lang=> 'lang' , files=>[ path_do_dic, path_to_aff ]}  )>

 Adds or modifies a lang entry in the config file of the module.

=cut

sub add_lang {
	return undef unless ( $_[1]->{lang} and $_[1]->{files});
	$config{ $_[1]->{lang} }=$_[1]->{files};
	write_config($confpath,\%config);
}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
