package Extensions::Tokenizer::default;

use feature ":5.10";
use strict;
use utf8;
use Carp;

our $VERSION='';

=pod

=head1 NAME

 Extensions::Tokenizer::default - simple regexp splitter.

=head1 DESCRIPTION

 This is a simple regexp splitter module. Nothing savvy.

=head1 METHODS

=over 4

=item - I<new( qr//? )>

 Optionally takes a regexp. If nothing is passed it splits at \s.

=cut 

sub new {
	my $self=$_[1]||qr/\s+/;
	return bless \$self,__PACKAGE__;
}

=item - I<rex(Regexp)>

 Changes the regexp used for splitting or grepping.

=cut

sub rex {
	return ${$_[0]}=$_[1];
}


=item - I<split($string)>

 Splits the string using the given regexp.
 or at \s.

=cut

sub split {
	return [ split( /${$_[0]}/, $_[1] ) ];
}

=item - I<grep($string)>

 Greps the substrings.

=cut

sub grep {
	my @dat=($_[1]=~/${$_[0]}/g);
	return \@dat;
}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
