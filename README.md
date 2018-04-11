# Sitewriter

This is a small Sinatra service that provides publishing endpoints for sites that cannot provide their own.

The first use case is Micropub posting of notes to [my Middleman site](https://hans.gerwitz.com/) via GitHub.

Essentially, a configured domain has some _endpoints_, which receive content and apply _templates_ which are then sent to a _store_.

Authentication for configuration is provided via IndieAuth.com

I also use IndieAuth for the Micropub tokens. If you'd like to do the same, set the environment variable `TOKEN_ENDPOINT` to `https://tokens.indieauth.com/token`

## Post type heuristics

- If `mp-type` is defined, use it
- If `type` == h-event or `h` == event: event
- If `type` == h-entry or `h` == entry:
  - If there is a `in-reply-to` value: reply
  - quotation
  - If there is a `repost-of` value: repost
  - If there is a `bookmark-of` value: bookmark
  - If there is a `checkin` or `u-checkin` value: checkin
  - If there is a `like-of` value: like
  - If there is a `video` value: video
  - If there is a `photo` value: photo
  - If there is a `audio` value: audio
  - If there is a `name` value: article
  - Otherwise: note

N.B. entries are flat. The value of a property may be an entry itself, but the "deeper" values will not be flattened for post type discovery.

## Credits

This was inspired by and initiated as a fork of Barry Frost's [Transformative](https://github.com/barryf/transformative).
