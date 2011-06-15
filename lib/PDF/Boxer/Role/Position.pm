package PDF::Boxer::Role::Position;
use Moose::Role;

requires qw!margin border padding!;

has 'margin_left' => ( isa => 'Int', is => 'ro', required => 1 );
has 'margin_top'  => ( isa => 'Int', is => 'ro', required => 1 );

has 'margin_right' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'margin_bottom'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'border_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'border_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'padding_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'padding_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

has 'content_left' => ( isa => 'Int', is => 'ro', lazy_build => 1 );
has 'content_top'  => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_margin_right{
  my ($self) = @_;
  return $self->margin_left + $self->margin_width;
}

sub _build_margin_bottom{
  my ($self) = @_;
  return $self->margin_top - $self->margin_height;
}

sub _build_border_left{
  my ($self) = @_;
  return $self->margin_left + $self->margin->[3];
}

sub _build_border_top{
  my ($self) = @_;
  return $self->margin_top - $self->margin->[0];
}

sub _build_padding_left{
  my ($self) = @_;
  return $self->border_left + $self->border->[3];
}

sub _build_padding_top{
  my ($self) = @_;
  return $self->border_top - $self->border->[0];
}

sub _build_content_left{
  my ($self) = @_;
  return $self->padding_left + $self->padding->[3];
}

sub _build_content_top{
  my ($self) = @_;
  return $self->padding_top - $self->padding->[0];
}

sub dump_position{
  my ($self) = @_;
  my @lines = (
    '== Pos ==',
    (sprintf 'Margin: %s %s %s %s', $self->margin_top, $self->margin_right, $self->margin_bottom, $self->margin_left),
    (sprintf 'Border: %s x %s', $self->border_left, $self->border_top),
    (sprintf 'Padding: %s x %s', $self->padding_left, $self->padding_top),
    (sprintf 'Content: %s x %s', $self->content_left, $self->content_top),
  );
  $_ .= "\n" foreach @lines;
  return join('', @lines);
}

1;

