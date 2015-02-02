package Build::Graph::Node::Phony;

use strict;
use warnings;

use parent 'Build::Graph::Role::Node';

sub phony { 1 }

sub weak { 0 }

1;

#ABSTRACT: A dependency graph node for file targets

