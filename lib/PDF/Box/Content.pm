package PDF::Box::Content;
use Moose;
use namespace::autoclean;

has 'doc' => ( isa => 'Object', is => 'ro' );
has 'align' => ( isa => 'Str', is => 'ro' );
has 'value' => ( isa => 'Str', is => 'ro' );

sub render{}

__PACKAGE__->meta->make_immutable;

1;
