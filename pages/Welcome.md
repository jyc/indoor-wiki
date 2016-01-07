# Welcome!

Thanks for installing Indoor Wiki!

Here's a [link](/Welcome.md) to this page.
Here's a [link](http://google.com) to the outside.

# Keyboard Shortcuts

- `0` to jump to the parent directory.
- `1-9` to jump to directory entries 1 through 9.

# Configuration

See `indoor.toml`.

Example:

```toml
title = "Indoor Wiki"
static_path = "_indoor"
wiki_path = "pages"
highlight = true

[[links]]
label = "Home"
to = "/"

[[links]]
label = "Welcome"
to = "/Welcome.md"
```

# HTML Escaping

<b>Warning! HTML is not escaped.</b>

In `src/indoor_markdown.ml`, you can replace:

```ocaml
return @@ Cmark.to_html md
```

with

```ocaml
return @@ Cmark.to_html ~flags:[`Safe] md
```

to disallow raw HTML.
