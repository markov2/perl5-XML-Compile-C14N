#!/usr/bin/env perl

use warnings;
use strict;

use XML::Compile::Cache;
use XML::Compile::WSS;

my $schema = XML::Compile::Cache->new
  ( any_element  => 'ATTEMPT'
  , opts_readers => [mixed_elements => 'STRUCTURAL']
  , allow_undeclared => 1
  );
my $wss  = XML::Compile::WSS->new(version => '1.1', schema => $schema);

$schema->namespaces->printIndex;
my $data = $schema->reader('xenc:EncryptedData')->('enc-example.xml');

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

print Dumper $data;
