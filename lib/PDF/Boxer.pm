package PDF::Boxer;
use Moose;
use namespace::autoclean;

use PDF::Boxer::Box;
use PDF::Boxer::Content::Text;
use Try::Tiny;

has 'doc' => ( isa => 'Object', is => 'ro' );

has 'margin_left' => ( isa => 'Int', is => 'rw', default => 0 );
has 'margin_top'  => ( isa => 'Int', is => 'rw', lazy_build => 1 );
sub _build_margin_top{ shift->max_height }

has 'max_width' => ( isa => 'Int', is => 'rw', default => 595 );
has 'max_height'  => ( isa => 'Int', is => 'rw', default => 842 );

has 'parent_box' => ( isa => 'PDF::Boxer::Box', is => 'rw' ); 
has 'sibling_box' => ( isa => 'PDF::Boxer::Box', is => 'rw', clearer => 'clear_sibling_box' ); 

sub add_to_pdf{
  my ($self, $spec) = @_;
  
  my $contents = delete $spec->{contents};

  my $box = try{
    $self->inflate($spec);
  } catch {
    warn "Parent: ".$self->parent_box->name if $self->parent_box;
    die $_;
  };

  $box->render();

  $self->margin_left($box->content_left);
  $self->margin_top($box->content_top);

  $self->parent_box($box);

  foreach(@$contents){
    $self->sibling_box($self->add_to_pdf($_));
  }

  if ($box->display eq 'block'){
    die 'how did we get here?' unless $self->parent_box;
    # set margin_left to left-most point of outer box..
    $self->margin_left($self->parent_box->content_left);
# need to set margin_top to previous contents bootom margin for text?
    $self->margin_top($self->sibling_box->margin_top - $self->sibling_box->margin_height);
  } else {
    $self->margin_left($box->margin_left + $box->margin_width + 1);
  }

  $self->clear_sibling_box;

  return $box;
 
}

sub inflate{
  my ($self, $spec) = @_;

  my $class = 'PDF::Boxer::Box';
  if ($spec->{type} && lc($spec->{type}) ne 'box'){
    $class = 'PDF::Boxer::Content::'.$spec->{type};
  }

  return $class->new({
    boxer => $self,
    max_width => $self->parent_box ? $self->parent_box->width : $self->max_width,
    max_height => $self->parent_box ? $self->parent_box->height : $self->max_height,
    margin_left => $self->margin_left,
    margin_top => $self->margin_top,
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

