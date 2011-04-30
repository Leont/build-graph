package Graph::Dependency::Action;
use Any::Moose 'Role', '::Util::TypeConstraints';

use Graph::Dependency::Action::Sub;

coerce 'Graph::Dependency::Action' => from 'CodeRef', via { Graph::Dependency::Action::Sub->new(callback => $_) };

requires 'execute';

1;


__END__

=method execute

This role requires this method. It's run when the action is executed.
