package Shared::Config::Tools;

use strict;
use feature ":5.10";
use utf8;
use Carp;
use Term::ReadLine;
use Term::UI;
use Shared::Load qw(load);
=pod

=head1 NAME

 Shared::Config::Tools - some helper methods to check dependencies and
 			 setting paths.

=head1 METHODS

=cut


=pod

 - new() 	constructor.
=cut

my $self;
my $pdir;
my $term = Term::ReadLine->new('config');
sub new {
	return $self if $self;
	my $self={
		deps=>''};
	bless $self,$_[0];
}


=pod

 - create_dependency_list ( \%deps )    accepts a hashref with the top-level directory to scan from { dir => $path },
	   	     			Scans the files from the toplevel directory for 'use' lines. The results are 
		       		        in the object's blessed hash under found and missing keys.
=cut

sub create_dependency_list {
	say "\n\e[36mChecking dependencies.\e[0m";
	my $self=shift;
	my $opts=shift;
	return undef unless -d $opts->{dir};
	
	$DB::single=1;
	my @files=_get_filelist($opts->{dir});

	foreach my $file (@files) {
		open my $FILE,'<', $file or do {
			return undef ;
			};

			say " Checking $file ";

		my $step;	# this is a step switch
		while (<$FILE>) {
			next if /(?:^\W$)/;			# excl. empty lines
			next if /(?:\s*#)/;			# also drop comment line

			$step=undef if /^=cut/;			# drop all between =pod
			next if $step;
			( $step = 1 and next ) if /^=pod/;	# and =cut

			chomp;

			next if /.*(KATA|Shared|CGI)/;		# drop KATA namespaces and check only external deps
									# if internal deps are needed implement here

			next unless s/^(?:[\s]*+use[\s]+)  		# group \suse\s pattern, any number of \s 
						([A-Z][\w|::]++)	# catch Module::Name kind of pattern
						(?:[\s|;]*+.*+)		# group the rest: \s or ; and anything
						/$1/x;			# we need only the catched group: Module::Name etc. pattern

			if ( eval "require $_" ) {	
				if (my $ver = $self->check_version($_) )  {
					$_.=' '.$ver;
					push @{ $self->{missing}{$_} },$file;
					say "\t\e[31m ! Missing dependency\e[0m $_";
					next;
					};
				push @{ $self->{found}{$_} },$file;
			} else {
				push @{ $self->{missing}{$_} },$file;
				say "\t\e[31m ! Missing dependency\e[0m $_";
			}
		} # WHILE <FILE>
	}
	say;
	return;
}

=pod
- check_extmodules()	  takes an array(ref) of Perl module names. checks the passed module list 
                          against the installed modules using ExtUtils::Installed. If it fails,
			  the function tries to  eval the module. Returns undef on 
			  success,failed modules on error.
=cut

sub check_extmodules  {
	my ($self,@mod) = @_;
	my (@missing);
	say "Checking module dependency...\t";

	if ( ref ($mod[0]) eq 'ARRAY') {
		@mod=@{$mod[0]};
	}

	my %installed;
	%installed=map { $installed{$_} } ExtUtils::Installed->new()->modules();
	@missing=grep{ ! $installed{$_} } @mod;
	
	unless (@missing) {
		say "\t...OK.";
		return undef;   	 
	}

	my @to_install;
	if ( @missing ) {
		foreach (@missing) {
			if ( load $_ )  { 		# do a manual check. ExtUtils can be wrong with core modules.
				next;
				}
	
			say "\e[31mMissing: $_\e[0m";
			push @to_install,$_;
		}
	}
	print "done.\n";
	return undef if ! @to_install;
	return @to_install;
}

# put version into deps file with regexp or versions must be recorded here too. TODO
sub check_version {
	my %needed = (
		"Array::Utils" => 0.5,
	);
	my ($self,$mod) = @_;
	no strict;
	my $ver=${"$mod\::VERSION"};
	return $ver if ( $ver < $needed{$mod} );
	return undef;
}

=pod

 - get_deps           returns the ordered list of dependencies. For pretty printing.
=cut

sub get_deps {
	my $self=shift;
	my $key = shift || 'found';
	(warn "Neither 'found' nor 'missing' is provided as argument." and return undef)  if ($key !~ /found|missing/);
	
	if (wantarray) {
		return sort( keys( %{$self->{$key}} ) );
		} else {
		return $self->{$key};
		}
}

=pod

 - external_progs	checks for external programs calling the 'which' command.
                        This is not portable.
=cut

sub external_progs {	# check for external program dependencies calling bash 'which'
	my ($self,@list) = @_;
	my %found;
	foreach my $needed (@list) {
		open my $BASH,'which '.$_.' 2>/dev/null |';
		while (my $line=<$BASH>) {
			$found{$needed}=$line if $line=~/$needed$/;
		}
	}
	return %found;
}


=pod

 - set_paths            uses a hasref with path description (prompt) and default value.
                        asks the user to enter the paths.
=cut
sub set_path {
	my $prompt;
	given ($_[1]) {
		when ( "ARRAY" ) {
			$prompt = { %{$_[1]} };
		};
		when ( "HASH" ) {
			$prompt=$_[1];	# prompt -> default value for directories
		};
		default { 
		        $prompt={ @_[1..$#_] };
		};
	};
	# prompt directories.
	my $path;
		while (1) {
			$path=$term->get_reply(  prompt=> "\n\e[36mTarget for $_\e[0m",
				    default=> $prompt->{$_},
				    );
			exit "User terminated." if $path =~/q|quit|exit/;
			unless (-e $path) {
				my $yesno= $term->ask_yn( prompt=>"$path directory does not exists. Shall I create it?",
						  default=>"y",);

				exit "User terminated." if $yesno =~/q|quit|exit/;
				if ($yesno) {
					if (system("mkdir $path -p 2>/dev/null") !=0 ) { 
						say "Cannot create $path directory!\n$!";
						die;
					} else {
					say "Directory $path created.";
					last;
					};
				} else {
					say "No workdir is given.";
					redo;
				}
			} else {
				say "\e[31m[ ! ]\e[0m Directory exists. Are you sure you want to use that?\n";
				my $resp=$term->get_reply(prompt=>'Default: Keep. Enter option: ',
					     	   choices =>['Keep','Clean up','quit'],
					   		default=>'Keep',);
				if ($resp eq "Clean up") {
					say "\e[36m------>\e[0m $resp";
					system("rm -r $path* 2>/dev/null"); # TODO: not too smart
				}
				last;
			}
		}
	return $path;
};	

=pod

 - fill_form	    accepts a HASH of key-value pairs and
 		    prompts user to validate values.
=cut

sub get_reply {
	my ($self,%prompt)=@_;
	my $input=$term->get_reply( %prompt );
	return undef if $input=~/q|quit|exit/;	
	return $input;
}


# simply make a filelist traversing the subdirs
# doing some filtering and returning the list of perl files.
# this is used instead of File::Find and alikes. Those seem to 
# have one advantage, that is managing symlinks properly. On this demand
# change code here. File::Find is not OO and does some mess-up with
# this design. File::Find::Object is probably a better choice.
sub _get_filelist {
	my $dir=$_[0];
	my (@return,@dirs);
	opendir MYDIR,$dir;
	while (my $file=readdir MYDIR) {
		next if $file =~/^\./;
		$file=join('/',$dir,$file);
		( push @dirs,$file and next) if (-d $file);
		next if $file !~ /(?:p[ml]|plx)$/;  # skip non perl files (pm,plx,pl) 
		push @return,$file if -f $file;
		next;
	}
	 
	if (@dirs) {
		foreach (@dirs) {
		push @return, _get_filelist($_);
		}
	}
	return @return;
}

1;
__END__
=head1 TODO
 
 Dependency checking should go into a separate module.
 
=head1 AUTHOR & COPYRIGHT

(C) Laslo Forro salmonix_at_gmail_dot.com
The concept of KATA and the code is GPLv2. licensed. If you are not familiar
with this license pls. visit the link below to read it:
http://www.gnu.org/licenses/gpl-2.0.html


2010-06-13

