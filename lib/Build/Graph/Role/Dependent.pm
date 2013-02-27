package Build::Graph::Role::Dependent;

use Moo::Role;

requires 'dependencies';

1;

# ABSTRACT: A role for other roles to communicate their dependencies
