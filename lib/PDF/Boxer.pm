package PDF::Boxer;
use Moose;
use namespace::autoclean;

use PDF::Boxer::Box;
use PDF::Boxer::Content::Text;
use PDF::Boxer::Content::Image;
use Try::Tiny;
use DDP;

has 'doc' => ( isa => 'Object', is => 'ro' );

has 'content_margin_left' => ( isa => 'Int', is => 'rw', default => 0 );
has 'content_margin_top'  => ( isa => 'Int', is => 'rw', lazy_build => 1 );
sub _build_content_margin_top{ shift->max_height }

has 'max_width' => ( isa => 'Int', is => 'rw', default => 595 );
has 'max_height'  => ( isa => 'Int', is => 'rw', default => 842 );

#has 'parent_box' => ( isa => 'PDF::Boxer::Box', is => 'rw', clearer => 'clear_parent_box' ); 
has 'sibling_box' => ( isa => 'PDF::Boxer::Box', is => 'rw', clearer => 'clear_sibling_box' ); 

has 'box_stack' => ( isa => 'ArrayRef', is => 'ro', default => sub{[]} ); 

sub parent_box{
  my ($self) = @_;
  return $self->box_stack->[0];
}

sub add_to_pdf{
  my ($self, $spec) = @_;
  
  my $contents = delete $spec->{contents};

  warn "\n### current: ".$spec->{name} ."\n";
  warn "\n### parent: ".($self->parent_box ? $self->parent_box->name : 'none')."\n";
  warn $self->parent_box->dump_position if $self->parent_box;
  warn $self->parent_box->dump_size if $self->parent_box;
  warn "\n### sibling: ".($self->sibling_box ? $self->sibling_box->name : 'none')."\n";
  warn $self->sibling_box->dump_position if $self->sibling_box;
  warn $self->sibling_box->dump_size if $self->sibling_box;
  warn $self->sibling_box->dump_spec if $self->sibling_box;

  $spec->{max_width} = $self->max_width;
  $spec->{max_height} = $self->max_height;

  if (my $parent = $self->parent_box){
warn "# set parent";
    $spec->{margin_left} = $parent->content_left;
    $spec->{margin_top} = $parent->content_top;
    $spec->{max_width} = $parent->width;
    $spec->{max_height} = $parent->height;
  }
  if (my $sibling = $self->sibling_box){
    if ($sibling->pressure_width){
warn "# set sibling pressure_width";
      $spec->{margin_top} = $sibling->margin_bottom;
    } else {
warn "# set sibling no pressure_width";
      $spec->{margin_left} = $sibling->margin_right;
      $spec->{max_width} = $self->max_width - $sibling->margin_right;
    }
  }

warn p($spec);


  my $box = try{
    $self->inflate($spec);
  } catch {
    warn "Parent: ".$self->parent_box->name if $self->parent_box;
    die $_;
  };


  warn "Render ".$box->name."\n";
  $box->render();

  $self->content_margin_left($box->content_left);
  $self->content_margin_top($box->content_top);

  unless($box->pressure_width){
    warn "no box pressure_width\n";
    $self->content_margin_left($box->margin_left + $box->margin_width + 1);
  }

  unshift(@{$self->box_stack}, $box);

  $self->clear_sibling_box;
  foreach(@$contents){
    $self->sibling_box($self->add_to_pdf($_));
  }

 # $self->clear_sibling_box;

  shift @{$self->box_stack} if @{$self->box_stack} > 1;

  # set position (margin top and margin left) for next box





#  $self->clear_sibling_box;

  return $box;
 
}

sub inflate{
  my ($self, $spec) = @_;

  $spec->{type} ||= 'Box';

  my $class = 'PDF::Boxer::Box';
  if ($spec->{type} ne 'Box'){
    $class = 'PDF::Boxer::Content::'.$spec->{type};
  }

  return $class->new({
    boxer => $self,
    margin_left => 0,
    margin_top => $self->max_height,
    %$spec
  });

}

=head1 NAME

PDF::Boxer

=head1 SYNOPSIS

  $boxer = PDF::Boxer->new({
    doc => PDF::Boxer::Doc->new({ file => 'test.pdf' }),
  });

  $box => {
    max_width => '595',
    max_height => '842',
    contents => [
      {
        padding => 5,
        height => 80,
        display => 'block',
        background => 'lightblue',
        contents => [
          {
            margin => '10 5',
            border => 1,
            padding => '5 10 15 20',
            width => 200,
            contents => [
              {
                contents => [
                  { type => 'Text', value => ['Tax Invoice'], size => 36, color => 'black' },
                ],
              },
            ],
          },
          {
            margin => 0,
            border => 0,
            padding => 10,
            display => 'block',
            contents => [
              {
                contents => [
                  { type => 'Text', align => 'right', value => ['Eight Degrees Off Centre'], size => 20, color => 'black' },
                  { type => 'Text', align => 'right', value => [
                    '3 Bondi Cres, Kewarra Beach, Qld 4879',
                    '(07) 4055 6926  enquiries@eightdegrees.com.au'], size => 14, color => 'black' },
                ],
              },
            ],
          },
        ]
      },
    ],
  };

  $boxer->add_to_pdf($box);

=head1 DESCRIPTION

Use a type of "box model" layout to create PDFs.

=cut





__PACKAGE__->meta->make_immutable;

1;

