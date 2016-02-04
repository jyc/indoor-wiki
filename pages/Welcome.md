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

# Embedding

You can embed files in other files with the *\[%embed path]* syntax.
Indoor Wiki will preprocess your Markdown files and replace occurrences of the embedding syntax with the contents of the file they refer to.
`path` is interpreted relative to the `static_dir`.

For example, here's this page's stylesheet:

```css
[%embed css/style.css]
```

If you specify a non-existent file (or a file outside `static_path`), an error message is displayed:

[%embed does/not/exist]

If you want to embed files outside of your `static_dir`, you can use symbolic links.
