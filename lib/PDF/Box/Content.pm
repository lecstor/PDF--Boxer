package PDF::Box::Content;
use Moose;
use namespace::autoclean;

has 'align' => ( isa => 'Str', is => 'ro' );
has 'value' => ( isa => 'Str', is => 'ro' );

sub inflate{}

__PACKAGE__->meta->make_immutable;

1;
