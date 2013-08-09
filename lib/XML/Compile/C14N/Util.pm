use warnings;
use strict;

package XML::Compile::C14N::Util;
use base 'Exporter';

my @c14n = qw/
  C14N_v10_NO_COMM
  C14N_v10_COMMENTS
  C14N_v11_NO_COMM
  C14N_v11_COMMENTS
  C14N_EXC_NO_COMM
  C14N_EXC_COMMENTS
  C14N_EXC_NS
 /;

my @paths = qw/
  C14N10
  C14N11
  C14NEXC  
 /;

our @EXPORT      = qw/C14N_EXC_NS/;
our @EXPORT_OK   = (@c14n, @paths);
our %EXPORT_TAGS = (c14n => \@c14n, paths => \@paths);

=chapter NAME
XML::Compile::C14N::Util - constants for XML::Compile::C14N

=chapter SYNOPSYS
 use XML::Compile::C14N::Util ':c14n';

=chapter DESCRIPTION
This module collects constants used by various standards related
to XML Canonicalization.

=chapter FUNCTIONS

=section Constants
=cut

# Path components
use constant
  { C14N10   => 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
  , C14N11   => 'http://www.w3.org/2006/12/xml-c14n11'
  , C14NEXC  => 'http://www.w3.org/2001/10/xml-exc-c14n'
  };

=pod

Export tag C<:c14n> provides

=cut

use constant
  { C14N_v10_NO_COMM  => C14N10
  , C14N_v10_COMMENTS => C14N10. '#WithComments'
  , C14N_v11_NO_COMM  => C14N11
  , C14N_v11_COMMENTS => C14N11. '#WithComments'
  , C14N_EXC_NO_COMM  => C14NEXC.'#'             
  , C14N_EXC_COMMENTS => C14NEXC.'#WithComments'
  , C14N_EXC_NS       => C14NEXC.'#'
  };

1;
