package Graph::Dependency::Abstract::Action;
use Any::Moose 'Role', '::Util::TypeConstraints';

use Graph::Dependency::Abstract::Action::Sub;

coerce 'Graph::Dependency::Abstract::Action' => from 'CodeRef', via { Graph::Dependency::Abstract::Action::Sub->new(callback => $_) };

requires 'execute';

1;


__END__

=method execute

This role requires this method. It's run when the action is executed.
