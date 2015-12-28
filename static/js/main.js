"use strict";

if (hljs) {
  InstantClick.on("change", function() {
    $("pre code").each(function(i, block) {
      hljs.highlightBlock(block);
    });
  });
}

function instantKey(combo, el) {
  $(document).bind("keydown", combo, function () {
    InstantClick.preload(el.href);
  });
  $(document).bind("keyup", combo, function () {
    InstantClick.display(el.href);
  });
}

InstantClick.on("change", function () {
  for (var i = 1; i <= 9; i++) {
    var id = "directory-entry-" + i.toString();
    var els = $("#" + id);
    if (els.length == 0) {
      continue;
    }
    instantKey(i.toString(), els.get(0));
  }
  instantKey("0", $("#parent-directory-entry").get(0));
});

InstantClick.on("change", function () {
  if (MathJax) {
    MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
  }
});

// This script tag should be loaded with data-no-instant.
// Then this will only be run once: after the initial page has been loaded.
// This is what InstantClick needs.
$(document).ready(function () {
  InstantClick.init();
});

/* vim: set ts=2 sw=2 expandtab : */
