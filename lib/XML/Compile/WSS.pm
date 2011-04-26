use warnings;
use strict;

package XML::Compile::WSS;

use Log::Report 'xml-compile-wss';

use XML::Compile::WSS::Util ':wss11';
use XML::Compile::Util       qw/SCHEMA2001/;

use File::Basename           qw/dirname/;

my @prefixes11 = 
 ( wss  => WSS_11,  wsu    => WSU_10,    wsse  => WSSE_10
 , ds   => DSIG_NS, dsig11 => DSIG11_NS, dsigm => DSIG_MORE_NS
 , xenc => XENC_NS, ghc    => GHC_NS,    dsp   => DSP_NS
 );

my %versions =
  ( '1.1' => {xsddir => 'wss11', prefixes => \@prefixes11}
  );

=chapter NAME
XML::Compile::WSS - Web Service Security standards by W3C

=chapter SYNOPSIS

 my $schema = XML::Compile::Cache->new(...);
 my $wss    = XML::Compile::WSS->new(version => '1.1'
   , schema => $schema);
 
 use XML::Compile::WSS::Util ':wss11'

=chapter DESCRIPTION
The Web Service Security working group of W3C develops a set of
standards which add signatures and encryption to XML.

In its current status, this module supports parsing of the
meta-data, however there is no support for in-file encryption
or signature checking yet.

=chapter METHODS

=section Constructors

=c_method new OPTIONS

=requires version '1.1'|MODULE
Explicitly state which version WSS needs to be produced.
You may use a version number. You may also use the MODULE
name, which is a namespace constant, provided via C<::Util>.
The only option is currently C<WSS11MODULE>.

=option  schema M<XML::Compile::Cache>
=default schema C<undef>
Add the WSS extension information to the provided schema.  If not used,
you have to call M<loadSchemas()> before compiling readers and writers.
=cut

sub new(@) { my $class = shift; (bless {}, $class)->init( {@_} ) }
sub init($)
{   my ($self, $args) = @_;
    my $version = $args->{version}
        or error __x"explicit wss_version required";
    trace "initializing wss $version";

    $version = '1.1'
        if $version eq WSS11MODULE;

    $versions{$version}
        or error __x"unknown wss version {v}, pick from {vs}"
             , v => $version, vs => [keys %versions];
    $self->{XCW_version} = $version;

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

sub version() {shift->{XCW_version}}
sub schema()  {shift->{XCW_schema}}

#-----------

=section Handling

=method loadSchemas SCHEMA
SCHEMA must extend M<XML::Compile::Cache>.
=cut

sub loadSchemas($)
{   my ($self, $schema) = @_;

    $schema->isa('XML::Compile::Cache')
        or error __x"loadSchemas() requires a XML::Compile::Cache object";
    $self->{XCW_schema} = $schema;

    my $version = $self->version;
    my $def = $versions{$version};

    my $prefixes = $def->{prefixes};
    $schema->prefixes(@$prefixes);
    {   local $" = ',';
        $schema->addKeyRewrite("PREFIXED(@$prefixes)");
    }

    (my $xsddir = __FILE__) =~ s! \.pm$ !/$def->{xsddir}!x;
    my @xsd = glob "$xsddir/*.xsd";

    trace "loading wss for $version";

    $schema->importDefinitions
       ( \@xsd

         # Missing from wss-secext-1.1.xsd (schema BUG)  Gladly, all
         # provided schemas have element_form qualified.
       , element_form_default => 'qualified'
       );

    # Another schema bug; attribute wsu:Id not declared qualified
    my ($wsu, $xsd) = (WSU_10, SCHEMA2001);
    $schema->importDefinitions( <<__PATCH );
<schema
  xmlns="$xsd"
  targetNamespace="$wsu"
  elementFormDefault="qualified"
  attributeFormDefault="qualified">
    <attribute name="Id" type="ID" />
</schema>
__PATCH

    $self;
}

=section SEE ALSO
=over 4
=item XML Signature Syntax and Processing (Second Edition)
F<http://www.w3.org/TR/2008/REC-xmldsig-core-20080610/>, 10 June 2008

=item XML Encryption Syntax and Processing
F<http://www.w3.org/TR/2002/REC-xmlenc-core-20021210/>, 10 December 2002

=item XML Security Generic Hybrid Ciphers
F<http://www.w3.org/TR/2011/CR-xmlsec-generic-hybrid-20110303/>, 3 March 2011

=item XML Signature Properties
F<http://www.w3.org/TR/2011/CR-xmldsig-properties-20110303/>, 3 March 2011

=item XML Signature Syntax and Processing Version 1.1
F<http://www.w3.org/TR/2011/CR-xmldsig-core1-20110303/>, 3 March 2011

=item RFC4050 Using the ECDSA for XML Digital Signatures
F<http://www.ietf.org/rfc/rfc4050.txt>, april 2005

=item RFC4051 Additional XML Security Uniform Resource Identifiers (URIs)
F<http://www.ietf.org/rfc/rfc4051.txt>, april 2005

=back
=cut

1;
