# Sitewriter

This is a small Sinatra service that provides publishing endpoints for sites that cannot provide their own.

The first use case is Micropub posting of notes to [my Middleman site](https://hans.gerwitz.com/) via GitHub.

Essentially, a configured domain has some _endpoints_, which receive content and apply _templates_ which are then sent to a _store_.

Authentication for configuration is provided via IndieAuth.com

I also use IndieAuth for the Micropub tokens. If you'd like to do the same, set the environment variable `TOKEN_ENDPOINT` to `https://tokens.indieauth.com/token`

## Credits

This was inspired by and initiated as a fork of Barry Frost's [Transformative](https://github.com/barryf/transformative).
