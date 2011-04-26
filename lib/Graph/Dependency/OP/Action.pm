package Graph::Dependency::OP::Action;
use Any::Moose 'Role', '::Util::TypeConstraints';

coerce 'Graph::Dependency::OP::Action' => from 'CodeRef', via { Graph::Dependency::OP::Action::Sub->new(callback => $_) };

requires 'execute';

1;

__END__

=method execute

This role requires this method. It's run when the action is executed.
