package Graph::Dependency::OP::Action;
use Any::Moose 'Role';

requires 'execute';

1;

__END__

=method execute

This role requires this method. It's run when the action is executed.
