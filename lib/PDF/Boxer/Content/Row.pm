package PDF::Boxer::Content::Row;
use Moose;
use namespace::autoclean;

extends 'PDF::Boxer::Box';

sub _build_pressure_width{ 1 }
sub _build_pressure_height{ 1 }

__PACKAGE__->meta->make_immutable;

1;
