#!/usr/bin/perl
package ALingua;

use feature ":5.10";
use strict;
use Exporter qw(import);
use AProfile;
use base qw( Class::Accessor::Fast);
our @EXPORT=qw($ALin);

=pod

=head1 NAME

 ALingua - Configuration singleton.

=head1 DESCRIPTION

 This singleton is configured by Config::Config, and shamelessly
 exports the $Config object.
 The exporters are not following the get_ set_ practice for only read only ones.

=cut

my $self;
my $home=$ENV{PWD}.'/ALingua/';
my $registered='Analictica.languages.yml';

sub new {
	return $ALingua::ALin if ( $ALingua::ALin and !$_[1]);
	die "No Linguadir exists at $home" unless -d $home;
	$registered=_read_linguafile($registered);
	if ( $registered->{$_[1]} ) {
		$AConf->set_lang($_[1]);
	};
	$self=change_language( $registered->{ $AConf->get_lang() });
	bless $self,__PACKAGE__ if !ref $self ne 'ALingua';
	__PACKAGE__->mk_ro_accessors( keys %$self );
	$ALingua::ALin=$self;
	return $self;

}

# construct new $self object reading the passed $lang parameter. Procedural in heart. 
sub change_language {
	my $lang=pop;
	if (my $messages = _read_linguafile($lang)) {
		%{$self}= %{$messages};
	}
	return $self;
};

sub linguas {	
	return keys %$registered;
}

sub in_use {
	return $AConf->get_lang();
};

sub _read_linguafile {
	open LAN,$home.$_[0] or die "$! $_[0]";
	my $data;
	while ( <LAN> ) {
		chomp;
		next if /^\s*\n$ | ^\s*#/; # empty lines and comments skip
		s/'//g;
		my ($k,$v)=split(/\s?:\s?/);
		$data->{$k}=$v;
	}
	close LAN;
	return $data;
}


1
__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO

 It is usually not a best practice to export sg. by default but
 we follow a bad practice with some 'project' globals.
