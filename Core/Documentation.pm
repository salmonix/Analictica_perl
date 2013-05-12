#!/usr/bin/perl
package Core::Documentation;

use feature ":5.10";

=pod

=head1 NAME

 Core::Documentation for Tokens, aToken, Search, and Textmatrix

=head1 DESCRIPTION

 These classes are not implemented in Core namespace. Their implementation
 is in the Persist::xx namespace, which modules are responsible for the actual
 instance and class management. The default is the Persist::memory, which uses
 a hash table to store all the data and uses Storable to serialize, 
 but other implementation - eg. database, network etc. - can also be made under 
 this namespace.
 The other objects are instantiated via the object Core::Tokens returns. 
 Core::Tokens reads the Persist module name to use from AProfile, 
 calls ->new() on it and returns the instance it receives.
 In this system every token is a list and vice versa. It means that every method
 is applicable in every instance of Core::Tokens. The only difference is that
 there is a _root instance always.

=head3 Methods inherited from base

=over 4

=item - I<add_class_method( 'method_name',$object )>

 This is to extend the class caller belongs to. 
 The $object is a CODE and accessible using the name 'method_name' 
 ( see callbacks, higher order functions ). It checks if the method name is occupied.
 If so, it is not overwritten but undef is returned and carped. 
 We expect that method names differ.

=item - I<if_has( { relation=E<gt>[ 'type','label' ] | associate =E<gt> 'label' } )>

 Checks if the instance has relation of a type -> label or associate of label.
 It is a kind of 'can'.


=item - I<get_textobject)

 Returns - initializes if needed the textobject.

=back

=head1 CLASS:

 Core::Tokens - The Token class.

=head1 DESCRIPTION

 The class implementing the concept of Core::Tokens is responsible for everything
 that is related to storing and indexing the list of tokens. Also each instance is
 a token itself, and each token is a list.

=head1 METHODS

=over 4

=item - I<new('project'?)>

 Takes a project name optionally (defaults to active) and returns the Persist::xx object,
 which is an actual implementation of Core::Tokens and the rest. This is the only
 method implemented in Core::Tokens package.

=item - I<aToken('token',HASH? )>

 Returns the instance.
 The parameter may set labels at creation.
 Built-in labels are processed by the Tokens instance automatically,
 the other labels are passed to the instance.
 Built-ins:

 'hide' labels move the token into a hide slot and does not add any 
 attribute to the token. There is no argument to pass in this case, so

 hide => 
	#PUNCTUATION
 	#STOPWORD
	#DELETED
 
 NOTE: pass only one hide label.
 NOTE: Asking for a hidden object will return undef.

 Other labels may take arguments (and this is the case with labels in general, see
 Associates below ), so use 

 use_labels => 
	{ #NORMAL => 'value' }     # the normal (eg. non dialectial) form of the token.

 ( or #ORIGINAL for the opposite and save some method calls, but that is your business.)


=item - I<commit>

 Commits the changes, eg. transactions or destroying object.

=item - I<delete_tokens( 'token'|$tokens)>

 Takes a token object or an ARRAY of token objects and hides them as
 #DELETED.

=item - I<get_frequencies($min,$max)>

 Returns a list of the objects in the freq range.
 If one value is passed it seeks for the objects with the passed freq.
 If nothing is passed, it returns all.
 At first call the method builds a cache if not created.

=item - I<get_ranks($min?,$max?)>

 Returns a list of the objects in the rank range (0 is the highest).
 If one value is passed it seeks for the objects with the passed rank.
 If nothing is passed, it returns all.
 At first call the method builds a cache if not created.

=item - I<get_token_names(ARRAY?)>

 Receives an $ARRAY of objects and returns an ARRAY of token-names.
 If nothing is passed, returns all the tokens names in frequency order.

=item - I<add/get/del_use_label($label)>
 
 Manages use_labels ARRAY. When any process is called the labels in this 
 array are called on the individual tokens one by one.

=item - I<add/get/del_hide_labels($label,$value?|CODE?)>

 Hide labels are attributes that make a token hidden moving it into a hide slot and
 removing them from any list. However, by default those are used when the text is 
 reconstructed.

=item The $can parameter in the followings checks if the object 'can' the passed method.
 If can't, B<undef> is returned - or skipped when a list or HASH is returned. 
 ( Memo: can? -> not )

=item - I<get_all_indexes( $can? )>

 Returns the full list of tokens, including the hidden ones.

=item - I<get_all_tokens( $can? )>

 Returns the full - unhidden - token=>object hash after processing
 the use_labels.

=item - I<get_members()>

 Returns an ARRAY of object having association to the caller.

=item - I<get_id( $id, $can? )>

 Returns the object with ID $id.

=item - I<get_token( 'name',$can? )>

 Returns the token named as 'name' filtering through the labels in use,
 calling ->process_use_labels internally. Returns the token or a dummy object.

=item - I<get_by_name( 'name' )>

 Returns the token named as 'name' WITHOUT filtering through anything. 

=item - I<process_use_labels($token,$labels?)>

 Takes a token and applies the labels either in $labels ARRAY or by default
 the use_labels of the Tokens instance.

=item - I<destroy_labels/associates('label')>

 Destroys the 'label' everywhere.

=back

=head1 Token methods

 The methods are responsible to the access of the token attributes that manage no list.
 Each token stores its own positional data which is used for counting and restoring the text.
 A token is a form (string) that knows its name, stores its frequency, id, its
 association to other tokens returning the associate.

=head1 METHODS

=over 4

=item - I<new( 'token' )>

 Creator for 'token' instance.

=item - I<store/get/unstore( 'label' )>

 Puts/gets/deletes a value into a 'label' slot. Slot must not start with underscore (_).

=item - I<get_token, get_rank, get_sumfreq, set_rank>

 Getters - and setters - for token, _rank and _sum_freq attributes.

=item - I<delete_me>
 
 Deletes the instance. (In reality it goes hidden with label #DELETED.)

=item - I<commit>

 Commits the changes.

=item - I<get_freq( [ $unit,$entry ]?  )  >

 Returns the frequency in $unit->$entry, eg. 'sen'->12 : in 12th. sentence (if any).
 If nothing is passed it returns the total number of occurrences of the token.

=item - I<add_freq( $unit,$entry)>

 Adds one to the frequency of the object in $unit->$entry.

=item - I<increment_freqs( $unit,$entry,$label)>

 Increments the frequency of the token in ALL associates that can add_freq.

=item - I<get_positions( $unit )>

 Returns the positions=>frequencies hash for $unit.

=item - I<get_name>

 Returns the token name.

=item - I<process_use_labels( ARRAY? )>

 Takes optionally an ARRAY of labels to process. If none is passed the 
 use_labels set in Tokens is processed. (Internally calls Tokens)

B<Associates>
 
 In our sense tokens are 'associated' to other tokens or objects or friendly monsters
 returning the swollen artifacts. These methods place, call and remove associates. 
 In programming terms associates are either objects or CODEs stored under the label.
 Calling them is nothing special, simply we do not address them directly, only via a 
 label.

=item - I<add_associate( 'label', $some_value? | CODE?,$arg? )>

 Associates a token with something, that can be accessed via associate() methods.
 If attribute is a CODE, then optional $arg is passed to it, eg. to
 instantiate a class. The CODE is responsible for processing the argument.
 See an example below at Core::Tokens -> Getters for a token.

=item - I<associate( 'label',$arg?)>

 Returns what label returns or undef if label does not exist.
 $arg is passed to the content of the label. See example below.

=item - I<del_associate('name')>

 Removes the associate from the object.

=item - I<get_who_associate('label')>

 Guess it.

=back

I<Let's see examples.> 

 Say, we store a distance of the token, which is #DIST and returns a float. 
 ( For some reason we want to store here not by using 'store' method. )  
 To construct it do:

 $tokens->add_associate($shire,'#DIST',$float); 

 And done. #DIST provides access to the value $float.
 
 my $distance=$shire->associate( '#DIST' );
 if ( !ref $distance ) { ..... };   # is it a scalar?
 
 Simple - we got a value.
 What if we store an object? Say, we need the frequency of a $token 
 and if $token is labeled (classed) as #SAURONS, we need the frequency of that instead.
 
   $my_precious=$tlist->get_token( $my_precious );        # get the token
   my $Saurons=$my_precious->associate('#SAURONS' );      # get the #SAURONS associate object
   $Saurons->get_freq;                       	          # and call freq on it.
	
 Why is it? 'cause we made the associate so earlier via add_associate:

   my $obj = $tokens_instance->aToken->new( $saurons_instance );  # make a new token with parameter
   $my_precious->add_associate('#SAURONS',$obj);

 We can also use object a bit more advanced. Eg. in a Class Mordor:

 sub distance {
    my (self,$obj) = @_;
    return sub { $self->calculate_distance ( $obj->get_position, $self->my_position ) }
 }

 In our program where $Mordor_inst is an instance of Class Mordor:

 $my_precious->add_associate('#DISTANCE_MORDOR',$Mordor_inst->distance($token));

 Now, we can call it as

 $my_precious->associate('#DISTANCE_MORDOR');

 More, we can also pass an argument in a REF. If the associate is a CODE,
 it may need a method call and an argument, so use
 
 { method_name => arg } 

 syntax.

 If the token can not associate, it gives itself back, so == can tell if associate was
 successful or not. Eg.
  
   my $assoc=$Tom_Bombadil->associate('#SAURONS');
   if ( $assoc == $Tom_Bombadil ) { ..... }       # Tom cares not of these affaires

 or in one line:
  
   if ( $assoc=$Tom_Bombadil->associate('#SAURONS') == $Toma_Bombadil ) { ... }


 NOTE and CAVEAT:
 Association integrity is granted with the $obj->associate('#LABEL') syntax 
 automatically calling $LABEL -> add_associate_from( $obj ). The objec has an array in
 _associate_from that gives the knowledge of who are associating the particular object 
 in the particular label, creating a Token instance in the background. If a ready-made
 object is provided then add_associate_from is tried for the same reason. When needed, 
 the get_associates_from is tried and an ARRAY is expected.

SUBCLASSING TO CORE TOKENS IS POSSIBLE HOW??????

 When CODE is provided, a HASH is sent as parameter: { add_associate_from => $self }, and when
 called, the 'associates_from' parameter is passed. The rest is up to the writer of the
 code.

 (If you are not clear what I mean check out ../Core/Analictica_associates.png diagram
 for better understanding of associate links and imagine how is it possible to reach
 the bottom when a new associate is added on the top.)

 NOTE:
 The problem is with instance methods and real OO. Perl is not OO, but so flexible
 that you can make it so. (Actually you can make perl a moose, that is a bit bizarre.)
 Regarding real instance methods Python is like Perl so beyond a simpler syntax 
 and stricter intendation - and put definitions first, execution last -
 there is little to gain. But Ruby... 
 Ruby allows adding methods to a particular instance. Plus neat syntax. Learn Ruby.

=over 4

=item - I<hide/if_hidden/hide_label/unhide ('label'?)>

 Hidden labels are a special type of associates. They drop the token from processing.
 Label may explain why object is hidden, but once used, it must be use consequently.
 Not applying label to 'hide' sets the flag simply 1.
 'hide_label( "label" )' checks if label matches the hide flag.

=back

=head1 CLASS:

 Persist::memory::Textmatrix

=head1 DESCRIPTION

 The Textmatrix module is responsible for storing the text in internal format.
 This format is the list of id's for a token.

=head1 METHODS

=over 4

=item - I<new($core_tokens>)

Takes a Core::Tokens instance and returns the Textmatrix object.

=item - I<start/close_unit('unit_type','name'?)>

 Starts/closes a unit. Type is like 'text', name is like 'El Aleph'. Name is optional.
 A unit can be opened any time again.

=item - I<get_names('unit_type')>

 Yes, returns the names.

=item - I<add_unit_in_use($unit|@units)>

 Adds the unit name to the in_use array. These are the units scanned by the program.

=item - I<del_unit_it_use($unit|@units)>

 Guess it.

=item - I<count_occurrences($units)>

 Counts the frequency of the items per unit and add the frequency to the
 tokens as unit=>{pos=> int ,sumfreq=>int }   frequency structure.
 Defaults to active_units unless @units is defined.

=back

=head1 BUGS, WARNINGS and TODO

 Make all the APIs into a contractual manner.
