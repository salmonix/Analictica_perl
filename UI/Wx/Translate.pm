#!/usr/bin/perl
package UI::Wx::Translate;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use ALingua;
use ALingua::Chunks;

our $VERSION='';

=pod

=head1 NAME

 UI::Wx::Translate - translate the xrc 'chunks' to the language in use. Singleton.

=head1 METHODS

=over 4

=item - I<new>

 Constructor.

=cut 

my $self;

sub new {
	return $self if $self;
	$self={};
	return bless $self,__PACKAGE__;
}

=item - I<translate($string,$lang?)>

 Takes a string to translate, the lang (optional) and returns the translated form.
 The string must contain ##TEXT## types of elements, as in HTML::Chunks.

=cut

sub translate {
	if ( $_[2] ) {
		$ALin->change_language( $_[2] ) ;
	}
	$_[1]=~s/##(\w+)##/$ALin->($1)/g;
	$_[1]=~s/##(\w+)##/$1/g; # rest is not translated
	return $_[1];
}

=item - I<translate_file($filename)>

 Returns the translated string, undef on failure.

=cut

sub translate_file {
	return undef unless -f $_[1];
	open FILE,$_[1];
	my $str=join('',<FILE>);
	return $_[0]->translate($str);
}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
