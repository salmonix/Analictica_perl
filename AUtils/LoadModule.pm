package AUtils::LoadModule;
# local test version

$VERSION = '0.1';

use strict;
use Carp;
use File::Spec ();
use feature ':5.10';

sub import {
    my $who = _who();

    {   no strict 'refs';
        *{"${who}::load_module"} = *load_module;
        *{"${who}::load_new_object"} = *load_new_object;
    }
}

sub load_new_object {
	my ($module,@params)=@_;
	load_module($module) or croak $!;
	return $module->new(@params);
}

sub load_module (*;@)  {
    my $mod = shift or return;

    if( _is_file( $mod ) ) {
        require $mod;
    } else {
        LOAD: {
            my $err;
            for my $flag ( qw[1 0] ) {
                my $file = _to_file( $mod, $flag);
                eval { require $file };
                $@ ? $err .= $@ : last LOAD;
            }
            if ($err) {
		    carp $err;
		    return undef;
	    };
        }
	return 1; # true on success
    }
    
    ### This addresses #41883: Module::Load cannot import 
    ### non-Exporter module. ->import() routines weren't
    ### properly called when load_module() was used.
    {   no strict 'refs';
        my $import;
        if (@_ and $import = $mod->can('import')) {
            unshift @_, $mod;
            goto &$import;
        }
    }
}

sub _to_file{
    local $_    = shift;
    my $pm      = shift || '';

    my @parts = split /::/;

    ### because of [perl #19213], see caveats ###
    my $file = $^O eq 'MSWin32'
                    ? join "/", @parts
                    : File::Spec->catfile( @parts );

    $file   .= '.pm' if $pm;
    
    ### on perl's before 5.10 (5.9.5@31746) if you require
    ### a file in VMS format, it's stored in %INC in VMS
    ### format. Therefor, better unixify it first
    ### Patch in reply to John Malmbergs patch (as mentioned
    ### above) on p5p Tue 21 Aug 2007 04:55:07
    $file = VMS::Filespec::unixify($file) if $^O eq 'VMS';

    return $file;
}

sub _who { (caller(1))[0] }

sub _is_file {
    local $_ = shift;
    return  /^\./               ? 1 :
            /[^\w:']/           ? 1 :
            undef
    #' silly bbedit..
}


1;

__END__

=pod

=head1 NAME

Shared::Load - runtime require of both modules and file. This is the shameless local copy of 
  Module::Load.

=head1 SYNOPSIS

	use Module::Load;

    my $module = 'Data:Dumper';
    load_module Core::Dumper;      # loads that module
    load_module 'Core::Dumper';    # ditto
    load_module $module            # tritto
    
    my $script = 'some/script.pl'
    load_module $script;
    load 'some/script.pl';	# use quotes because of punctuations
    
    load_module thing;             # try 'thing' first, then 'thing.pm'

    load_module CGI, ':standard'   # like 'use CGI qw[:standard]'
    

=head1 DESCRIPTION

C<load_module> eliminates the need to know whether you are trying to require
either a file or a module.

If you consult C<perldoc -f require> you will see that C<require> will
behave differently when given a bareword or a string.

In the case of a string, C<require> assumes you are wanting to load a
file. But in the case of a bareword, it assumes you mean a module.

This gives nasty overhead when you are trying to dynamically require
modules at runtime, since you will need to change the module notation
(C<Acme::Comment>) to a file notation fitting the particular platform
you are on.

C<load_module> eliminates the need for this overhead and will just DWYM.

The module carps the error message on failure and returns undef. On
success it returns True.

=head1 Rules

C<load_module> has the following rules to decide what it thinks you want:

=over 4

=item *

If the argument has any characters in it other than those matching
C<\w>, C<:> or C<'>, it must be a file

=item *

If the argument matches only C<[\w:']>, it must be a module

=item *

If the argument matches only C<\w>, it could either be a module or a
file. We will try to find C<file.pm> first in C<@INC> and if that
fails, we will try to find C<file> in @INC.  If both fail, we die with
the respective error messages.

=back

=head1 Caveats

Because of a bug in perl (#19213), at least in version 5.6.1, we have
to hardcode the path separator for a require on Win32 to be C</>, like
on Unix rather than the Win32 C<\>. Otherwise perl will not read its
own %INC accurately double load files if they are required again, or
in the worst case, core dump.

C<AUtils::LoadModule> cannot do implicit imports, only explicit imports.
(in other words, you always have to specify explicitly what you wish
to import from a module, even if the functions are in that modules'
C<@EXPORT>)

=head1 ACKNOWLEDGEMENTS

Thanks to Jonas B. Nielsen for making explicit imports work.

=head1 AUTHOR

This module was written by Jos Boumans E<lt>kane@cpan.orgE<gt>.
Slight modification regarding the return value and carping is
by Laslo Forro E<lt>getforum@gmail.comE<gt>.

=head1 COPYRIGHT

This library is free software; you may redistribute and/or modify it 
under the same terms as Perl itself.


=cut                               
