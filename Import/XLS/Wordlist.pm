package Import::XLS::Wordlist;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use base 'Import::Wordlist';

our $VERSION='';

=pod

=head1 NAME

 Import::XLS::Wordlist - import wordlist file from MS xls files ( 98-2003 binaries )

=head1 DESCRIPTION

 At the moment the module imports the first worksheet looking for the following
 format:
 word  | normal_form | cat1 | cat2 | cat3 etc.
 
 If 'normal_form' is found that is used. 
 In 'normal_form' column the following 'sigils' are accepted: 
 # - stopword
 @ - keep case (otherwise everything is lowercased)
 The sigils must be written as prefix, their order is not important.

 Categories (containerts in our terms )are subcategories read from left to right. 
 (cat1 is sub of cat2, which is sub of cat3 etc.)

=head1 METHODS

=over 4

=item - I<get_xlsdata>

 Returns a HASH as col1: key, rest: ARRAY.

=cut

sub get_wordlist {
	my ($row_min,$row_max,%words,$key,$value);
	use Spreadsheet::ParseExcel;
	my $parser  = Spreadsheet::ParseExcel->new();
	my $workbook;
#        $workbook = $parser->Parse($_[0]->{file},XLS::Formatter->new());
        $workbook = $parser->Parse($_[0]->{file});

           for my $worksheet ( $workbook->worksheets() ) {

               my ( $row_min, $row_max ) = $worksheet->row_range();
               my ( $col_min, $col_max ) = $worksheet->col_range();

               for my $row ( $row_min .. $row_max ) {
                   $key= $worksheet->get_cell( $row, $col_min )->value(); # get the key for the return hash
		   $words{$key}=[];
                   for my $col ( $col_min+1 .. $col_max ) {
			   if ( $worksheet->get_cell($row,$col) ) {
				  $value=$worksheet->get_cell( $row, $col )->value();
                 		      push @{$words{$key}},$value; 
			      }
	       	   } # end 'for my col'
       	       } # end 'for my row'
	    } # end 'for my worksheet'
	return \%words;
}

1;

package XLS::Formatter;

# this piece of code is shamelessly stolen from http://www.perlmonks.org/?node_id=551123
# by brian p. phillips bit by bit.

use strict;
use Carp;
use base 'Spreadsheet::ParseExcel::FmtDefault';
use Encode qw(decode);

# the super-class isn't very friendly to sub-classing, so we have to override this to make
# sure it's blessed into the right class
 sub new {
       my $class = shift;
       return bless {}, $class;
}

# the only other method we need to override...
sub TextFmt {
     my ($self,$data,$encoding) = @_;

# Spreadsheet::ParseExcel will pass in the encoding to us!
# or, it passes nothing in if it's iso-8859-1
	$encoding ||= 'iso-8859-1';
# we perform the decoding in a "fatal" manner so that if it fails,
# we'll just pass the data back as-is
	my $decoded = eval { decode($encoding,$data,1) } || $data;
	return $decoded;
}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
