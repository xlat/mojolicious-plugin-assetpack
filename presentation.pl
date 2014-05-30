#!/usr/bin/env perl
# MOJO_MODE=production morbo presentation.pl
use Mojolicious::Lite;

plugin 'Bootstrap3' => css => [], js => [], jquery => 0;
plugin 'PODRenderer';

$ENV{SASS_PATH} = Mojolicious::Plugin::Bootstrap3->asset_path('sass');

app->asset(
  'presentation.css' => qw(
    css/prettify.css
    css/impress-demo.css
    sass/presentation.scss
    sass/bootstrap.scss
  )
);

app->asset(
  'presentation.js' => qw(
    js/prettify.js
    js/impress.js
    js/assetpack.js
  )
);

get '/' => 'presentation';

app->helper(
  pre => sub {
    my $content = pop;
    my($self, %args) = @_;

    $self->tag(
      'pre',
      class => join(' ', qw( text-left ), grep { $_ } delete $args{class}), # prettyprint
      %args,
      Mojo::ByteStream->new($content->()),
    );
  },
);

app->helper(
  slide => sub {
    my($self, $name, %args) = @_;
    my $markup = $self->render_to_string(template => $name);
    my $n = $self->stash->{n} || 0;
    my $p = $self->stash->{p} || 0;

    $self->stash->{p}++ unless delete $args{stop};
    $self->stash->{n}++;
    for my $k (grep { $args{$_} } qw( y z scale rotate_z rotate_x rotate_y )) {
      (my $n = $k) =~ s!_!-!g;
      $args{"data-$n"} = delete $args{$k};
    }

    die "No markup for $name" unless $markup;

    $self->tag('div',
      id => $name,
      class => join(' ', 'step', grep { $_ } delete $args{class}),
      'data-x' => $p * (delete $args{x} || 1400),
      'data-z' => $p * -200,
      %args,
      sub { $markup },
    );
  },
);

app->defaults(layout => 'slides', title => 'Presentation');
app->start;
__DATA__
@@ presentation.html.ep
%= slide 'batman'
%= slide 'start', class => 'text-center'
%= slide 'toc'
%= slide 'asset', class => 'text-center'
%= slide 'assetpack', class => 'text-center'
%= slide 'preprocessor', stop => 1
%= slide 'formats', y => 800
%= slide 'define_asset_pre', y => -10, stop => 1
%= slide 'define_asset_plugin', y => 130, stop => 1
%= slide 'define_asset', y => 340, stop => 1
%= slide 'define_asset_post', y => 550
%= slide 'include_asset', y => 500
%= slide 'web_assets', y => 500
%= slide 'environment'
%= slide 'env_no_cache'
%= slide 'file_structure'
%= slide 'custom_add', y => 600
%= slide 'custom_override', y => 600
%= slide 'gotchas'
%= slide 'gotchas_filename'
%= slide 'sellingpoints'
%= slide 'extensions', y => -400
%= slide 'bootstrap3', y => -400
%= slide 'bootstrap3_usage', y => -400
%= slide 'demo'
%= slide 'end'

@@ layouts/slides.html.ep
<html>
<head>
  <title><%= title %></title>
  %= asset 'presentation.css'
</head>
<body class="impress-not-supported">
  <div class="fallback-message">
    <p>Your browser <b>doesn't support the features required</b> by impress.js, so you are presented with a simplified version of this presentation.</p>
    <p>For the best experience please use the latest <b>Chrome</b>, <b>Safari</b> or <b>Firefox</b> browser.</p>
  </div>
  <div class="menu">
  %= link_to 'Presentation mode', url_for('presentation')->query(present => 1), class => 'btn btn-success'
  </div>
  <div id="impress">
    %= content
  </div>
  %= asset 'presentation.js'
</body>
</html>
