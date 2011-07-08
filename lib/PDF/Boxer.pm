package PDF::Boxer;
use Moose;
# ABSTRACT: Create PDFs from a simple box markup language.

our $VERSION   = '1.00';

=head1 SYNOPSIS

  $pdfml = <<'__EOP__';
  <column max_width="595" max_height="842">
    <column border_color="blue" border="2">
      <row>
        <image src="t/lecstor.gif" align="center" valign="center" padding="10" scale="60" />
        <column grow="1" padding="10 10 10 0">
          <text padding="3" align="right" size="20">
            Lecstor Pty Ltd
          </text>
          <text padding="3" align="right" size="14">
            123 Example St, Somewhere, Qld 4879
          </text>
        </column>
      </row>
      <row padding="15 0">
        <text padding="20" size="14">
          Mr G Client
          Shop 2 Some Centre, Retail Rd
          Somewhere, NSW 2000
        </text>
        <column padding="20" border_color="red" grow="1">
          <text size="16" align="right" font="Helvetica-Bold">
            Tax Invoice No. 123
          </text>
          <text size="14" align="right">
            Issued 01/01/2011
          </text>
          <text size="14" align="right" font="Helvetica-Bold">
            Due 14/01/2011
          </text>
        </column>
      </row>
    </column>
    <grid padding="10">
      <row font="Helvetica-Bold" padding="0">
        <text align="center" padding="0 10">Name</text>
        <text grow="1" align="center" padding="0 10">Description</text>
        <text padding="0 10" align="center">GST Amount</text>
        <text padding="0 10" align="center">Payable Amount</text>
      </row>
      <row margin="10 0 0 0">
        <text padding="0 5">Web Services</text>
        <text name="ItemText2" grow="1" padding="0 5">
          a long description which needs to be wrapped to fit in the box
        </text>
        <text padding="0 5" align="right">$9999.99</text>
        <text padding="0 5" align="right">$99999.99</text>
      </row>
    </grid>
  </column>
  __EOP__

  $parser = PDF::Boxer::SpecParser->new;
  $spec = $parser->parse($pdfml);

  $boxer = PDF::Boxer->new( doc => { file => 'test_invoice.pdf' } );

  $boxer->add_to_pdf($spec);
  $boxer->finish;

=head1 DESCRIPTION

Use my version of a "box model" layout to create PDFs.
Use PDF::Boxer::SpecParser to parse a template written in the not so patented PDFML.
Suggestion: Use L<Template> to dynamically create your PDFML template. 

=head1 METHODS

=method add_to_pdf

  $boxer->add_to_pdf($spec);

=cut

use namespace::autoclean;

use PDF::Boxer::Doc;
use PDF::Boxer::Content::Box;
use PDF::Boxer::Content::Text;
use PDF::Boxer::Content::Image;
use PDF::Boxer::Content::Row;
use PDF::Boxer::Content::Column;
use PDF::Boxer::Content::Grid;
use Try::Tiny;
use Scalar::Util qw/weaken/;
use Moose::Util::TypeConstraints;

coerce 'PDF::Boxer::Doc'
  => from 'HashRef'
    => via { PDF::Boxer::Doc->new($_) };

has 'debug'   => ( isa => 'Bool', is => 'ro', default => 0 );

has 'doc' => ( isa => 'PDF::Boxer::Doc', is => 'ro', coerce => 1 );

has 'max_width' => ( isa => 'Int', is => 'rw', default => 595 );
has 'max_height'  => ( isa => 'Int', is => 'rw', default => 842 );

has 'box_register' => ( isa => 'HashRef', is => 'ro', default => sub{{}} ); 

sub register_box{
  my ($self, $box) = @_;
  return unless $box->name;
  weaken($box);
  $self->box_register->{$box->name} = $box;
}

sub box_lookup{
  my ($self, $name) = @_;
  return $self->box_register->{$name};
}

sub add_to_pdf{
  my ($self, $spec) = @_;

  my $weak_me = $self;
  weaken($weak_me);
  $spec->{boxer} = $weak_me;
  $spec->{debug} = $self->debug;

  my $class = 'PDF::Boxer::Content::'.$spec->{type};
  my $node = $class->new($spec);
  $self->register_box($node);
  $node->initialize;
#  $node->ruler_h;
  $node->render;
  return $node;
}

sub finish{
  my ($self) = @_;
  $self->doc->pdf->save;
  $self->doc->pdf->end;
}

__PACKAGE__->meta->make_immutable;

1;
