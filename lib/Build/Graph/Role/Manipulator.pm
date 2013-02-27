package Build::Graph::Role::Manipulator;

use Moo::Role;

with 'Build::Graph::Role::Dependent';

requires qw/manipulate_graph/;

1;

# ABSTRACT: A role for manipulators of a graph
