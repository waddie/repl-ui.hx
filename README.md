# repl-ui.hx

Shared Helix/Steel machinery for REPL-style plugins. Extracted from
[nrepl.hx](https://github.com/waddie/nrepl.hx) so other plugins can
reuse the buffer and formatting code.

## Modules

- `helix-context.scm` (`make-helix-context`): a hash of Helix API functions
  injected into the buffer helpers so they never call Helix directly.
- `buffer.scm` (`repl-buffer` struct, `repl-buffer:ensure/create/append`):
  create and append to a named scratch buffer in a split, restoring focus and
  mode. Handles the buffer being closed or hidden between appends.
- `format.scm` (`format-result-common`, `format-output-list`,
  `format-error-as-comment`, `take-first-line`, `whitespace-only?`): render an
  evaluation result hash (`'value`, `'output`, `'error`, `'ex`, `'interrupted`,
  `'ns`) into REPL buffer text, with caller-supplied prompt and error
  formatters.
- `counter.scm` (`make-eval-counter`, `eval-counter-next!`,
  `eval-counter-reset!`): per-session `repl:N:>` numbering.
- `coords.scm` (`char-offset->line-col`): rope offset to 1-indexed
  (line . column).
- `selection.scm` (`selection:primary`, `selection:buffer`, `selection:ranges`):
  extract evaluable text and its source location from the focused document.

## Install

```sh
forge pkg install --git https://github.com/waddie/repl-ui.hx
```

Then require the modules you need:

```scheme
(require "repl-ui.hx/buffer.scm")
(require "repl-ui.hx/format.scm")
```

## Licence

GNU AGPL v3 or later. See LICENSE.md.
