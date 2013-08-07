use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::MatchInstalled::All;
BEGIN {
  $Dist::Zilla::Plugin::Prereqs::MatchInstalled::All::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::Prereqs::MatchInstalled::All::VERSION = '0.1.0';
}

# ABSTRACT: Upgrade ALL your dependencies to the ones you have installed.

use Moose;
use Dist::Zilla::Plugin::Prereqs::MatchInstalled v0.1.1;
use MooseX::Types::Moose qw( ArrayRef HashRef Str Bool );




extends 'Dist::Zilla::Plugin::Prereqs::MatchInstalled';


has exclude => (
  is => ro =>,
  isa => ArrayRef [Str],
  lazy    => 1,
  default => sub { [] }
);
has _exclude_hash => (
  is => ro =>,
  isa => HashRef [Str],
  lazy    => 1,
  builder => '_build__exclude_hash',
);
has upgrade_perl => (
  is      => ro  =>,
  isa     => Bool,
  lazy    => 1,
  default => sub { undef }
);

around mvp_multivalue_args => sub {
  my ( $orig, $self, @args ) = @_;
  return ( 'exclude', $orig->( $self, @args ) );
};

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config      = $self->$orig();
  my $this_config = {
    exclude      => $self->exclude,
    upgrade_perl => $self->upgrade_perl,
  };
  $config->{ q{} . __PACKAGE__ } = $this_config;
  return $config;
};

sub _build__exclude_hash {
  my ($self) = @_;
  return { map { ( $_, 1 ) } @{ $self->exclude } };
}

sub _user_wants_excluded {
  my ( $self, $module ) = @_;
  return exists $self->_exclude_hash->{$module};
}

sub _user_wants_upgrade_on {
  my ( $self, $module ) = @_;
  if ( $module eq 'perl' and not $self->upgrade_perl ) {
    $self->log_debug(q[perl is a dependency, but we won't automatically upgrade that without upgrade_perl = 1]);
    return;
  }
  if ( $self->_user_wants_excluded($module) ) {
    return;
  }
  return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::MatchInstalled::All - Upgrade ALL your dependencies to the ones you have installed.

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    [Prereqs::MatchInstalled::All]
    ; upgrade_perl = 1  ; if you want to upgrade to your installed perl
    ; include these too if you don't want to force a perl upgrade indirectly.
    exclude = strict
    exclude = warnings

=head1 DESCRIPTION

This is a special case of L<<< C<< Dist::Zilla::Plugin::B<Prereqs::MatchInstalled> >>|Dist::Zilla::Plugin::B<Prereqs::MatchInstalled >>> that automatically upgrades all versions of all dependencies, unless asked not to.

=head2 PITFALLS

Presently, there is one very large gotcha about using this module, in that it will upgrade everything,
even things that don't make sense to upgrade.

For instance:

=head3 Local Versions

If you have a single dependency on your system you might use, which is locally patched, and locally patched in such a way the local version is more recent than any on CPAN, you should either 

=over 4 

=item a. Not use this module

=item b. Put that module in the exclusion list

=back

=head3 Non-Dual Life modules

This plugin is not very smart, and can't differentiate between modules that do exist on CPAN independent of perl, and modules that don't.

For instance, if you use C<Autoprereqs>, its very likely your distribution will add a dependency on either C<strict> or C<warnings>

This module will ask your user to upgrade those versions to thier latest versions, which will likely require them to upgrade their Perl installation to do so.

Which basically means for the mean time, either 

=over 4

=item a. You must be ok with end users needing more recent Perls

=item b. You should avoid upgrading those dependencies by either 

=over 4

=item a. Not using this plugin

=item b. Adding problematic modules to the exclusion list

=back

=back

=head1 ATTRIBUTES

=head2 C<exclude>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Prereqs::MatchInstalled::All",
    "inherits":"Dist::Zilla::Plugin::Prereqs::MatchInstalled",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
