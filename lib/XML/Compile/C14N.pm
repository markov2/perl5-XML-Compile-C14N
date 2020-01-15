# This code is part of distribution XML-Compile-C14N.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::C14N;

use warnings;
use strict;

use Log::Report 'xml-compile-c14n';

use XML::Compile::C14N::Util qw/:c14n :paths/;
use XML::LibXML  ();
use Scalar::Util qw/weaken/;
use Encode       qw/_utf8_off/;

my %versions =
 ( '1.0' => {}
 , '1.1' => {}
 );

my %prefixes =
  ( c14n => C14N_EXC_NS
  );

my %features =       #comment  excl
  ( &C14N_v10_NO_COMM  => [ 0, 0 ]
  , &C14N_v10_COMMENTS => [ 1, 0 ]
  , &C14N_v11_NO_COMM  => [ 0, 0 ]
  , &C14N_v11_COMMENTS => [ 1, 0 ]
  , &C14N_EXC_NO_COMM  => [ 0, 1 ]
  , &C14N_EXC_COMMENTS => [ 1, 1 ]
  );

=chapter NAME
XML::Compile::C14N - XML Canonicalization

=chapter SYNOPSIS
 my $schema = XML::Compile::Cache->new(...);
 my $c14n   = XML::Compile::C14N->new(schema => $schema);
 
=chapter DESCRIPTION
XML canonicalization is used to enforce an explicit formatting style
on de XML documents. It is required to have a reproducable output when,
for instance, digital signatures gets applied to parts of the document.

C14N currently has seen three versions: 1.0, 1.1, and 2.0.  Versions 1.*
need [C14N-EXC] version 1.0.  There is no support for version 2.0 in
L<XML::LibXML> yet, so also not provided by this module.

=chapter METHODS

=section Constructors

=c_method new %options
There can be more than one C14N object active in your program.

=option  version STRING
=default version '1.1'
Explicitly state which version C14N needs to be used.  C14N2 is not
yet supported.  If not specified, it is first attempted to derive the
version from the 'for' option.

=option  for   METHOD
=default for   C<undef>
[0.92] When a canonicallization METHOD is provided, that will be used to
automatically detect the C14N version to be loaded.

=option  schema M<XML::Compile::Cache> object
=default schema C<undef>
Add the C14N extension information to the provided schema.  If not used,
you have to call M<loadSchemas()> before compiling readers and writers.
=cut

sub new(@) { my $class = shift; (bless {}, $class)->init( {@_} ) }
sub init($)
{   my ($self, $args) = @_;

    my $version = $args->{version};
    if(my $c = $args->{for})
    {   $version ||= index($c, C14N10 )==0 ? '1.0'
                   : index($c, C14N11 )==0 ? '1.1'
                   : index($c, C14NEXC)==0 ? '1.1'
                   : undef;
    }
    $version ||= '1.1';
    trace "initializing v14n $version";

    $versions{$version}
        or error __x"unknown c14n version {v}, pick from {vs}"
             , v => $version, vs => [keys %versions];
    $self->{XCC_version} = $version;

    $self->loadSchemas($args->{schema})
        if $args->{schema};

    $self;
}

#-----------

=section Attributes

=method version
Returns the version number.
=method schema
=cut

sub version() {shift->{XCC_version}}
sub schema()  {shift->{XCC_schema}}

#-----------
=section Handling

=method normalize $type, $node, %options
The $type is one of the C14* constants defined in M<XML::Compile::C14N::Util>.  The $node is an M<XML::LibXML::Element>.  Returned is a normalized
byte-sequence, for instance to be signed.

=option  prefix_list ARRAY
=default prefix_list []
Then prefixes which are to be included in normalization, only used in
excludeNamespaces (EXC) normalizations.

=option  xpath EXPRESSION
=default xpath C<undef>
Only normalize a subset of the document.

=option  context M<XML::LibXML::XPathContext> object
=default context <created from NODE if needed>
=cut

sub normalize($$%)
{   my ($self, $type, $node, %args) = @_;
    my $prefixes  = $args{prefix_list} || [];

    my $features  = $features{$type}
        or error __x"unsupported canonicalization method {name}", name => $type;
    
    my ($with_comments, $with_exc) = @$features;
    my $serialize = $with_exc ? 'toStringEC14N' : 'toStringC14N';

    my $xpath     = $args{xpath};
    my $context   = $args{context} || XML::LibXML::XPathContext->new($node);

    my $canon     =
      eval { $node->$serialize($with_comments, $xpath, $context, $prefixes) };
#warn "--> $canon#\n";

    # The cannonicalization (XML::LibXML <2.0110) sets the utf8 flag.  Later,
    # Digest::SHA >5.74 downgrades that string, changing some bytes...  So,
    # enforce this output to be interpreted as bytes!
    _utf8_off $canon;

    if(my $err = $@)
    { #  $err =~ s/ at .*//s;
        panic $err;
    }
    $canon;
}

#-----------
=section Internals

=method loadSchemas $schema
Load the C14N schema to the global $schema, which must extend
M<XML::Compile::Cache>.

This method will be called when you provide a value for M<new(schema)>.
Otherwise, you need to call this when the global $schema is known in your
program.
=cut

sub loadSchemas($)
{   my ($self, $schema) = @_;

    $schema->isa('XML::Compile::Cache')
        or error __x"loadSchemas() requires a XML::Compile::Cache object";
    $self->{XCC_schema} = $schema;
    weaken $self->{XCC_schema};

    my $version = $self->version;
    my $def     = $versions{$version};

    $schema->addPrefixes(\%prefixes);
    my $rewrite = join ',', keys %prefixes;
    $schema->addKeyRewrite("PREFIXED($rewrite)");

    (my $xsd = __FILE__) =~ s! \.pm$ !/exc-c14n.xsd!x;
    trace "loading c14n for $version";

    $schema->importDefinitions($xsd);
    $self;
}

#-----------------
=chapter DETAILS

=section References

=over 4
=item [C14N-10] Canonical XML Version 1.0
F<http://www.w3.org/TR/xml-c14n>, 15 March 2001

=item [C14N-EXC] Exclusive XML Canonicalization Version 1.0
F<http://www.w3.org/TR/xml-exc-c14n/>, 18 July 2002

=item [C14N-11] Canonical XML Version 1.1
F<http://www.w3.org/TR/xml-c14n11/>, 2 May 2008

=item [C14N-20] Canonical XML Version 2.0
F<http://www.w3.org/TR/xml-c14n2/>, 24 January 2012
=back
=cut

1;
