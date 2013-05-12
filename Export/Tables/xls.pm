package Export::Tables::xls;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AUtils::LoadModule;
use base 'Export::Tables';

our $VERSION='';

=pod

=head1 NAME

 Export::Tables::xls - writes the table in xls formats. 

=head1 METHODS

=over 4

=item - I<new>

 Constructor. 

=cut 

sub new {
	my %module=(
		xlsx => 'Excel::Writer::XLSX',
		xls  => 'Spreadsheet::WriteExcel',
	);
	my $self,
	$_[1]->{type}||='xls';
	$_[1]->{xls}=load_new_object( $module{ $_[1]->{type} }, $_[1]->{file} );
	bless $_[1],__PACKAGE__;
	$_[1]->add_sheet( $_[1]->{sheet} );
	return $_[1];
}

sub add_sheet {
	if ( $_[0]->{data}[0] ) {
		$_[0]->write_data;
	}
	$_[0]->{writer}=$_[0]->{xls}->add_worksheet($_[1]);
	carp $_[0]->{writer};
}

sub write_data {
	my ($self)=@_;
	my $ws=$self->{writer};
	my ($col,$row);
	$row=1;
	my $max=$#{$self->{header}}+1;
	map { $ws->write($row,$col,$_); $col++;  } @{$self->{header}};
	foreach my $line ( @{$self->{data}} ) {
		$row++;
		$col=0;
		map { $_||=0; $ws->write($row,$col,$_); $col++; } @$line;
		for ( $col..$max ) {
			$ws->write($row,$_,0);
		}

	}
	$self->{header}=$self->{data}=[];
	carp "Cleaned header.";

}

sub close {
	$_[0]->write_data if ( $_[0]->{data} );
	$_[0]->{xls}->close or warn " Error closing file $!";
}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
