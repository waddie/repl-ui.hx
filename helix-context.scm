;; Copyright (C) 2026 Tom Waddington
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; helix-context.scm - Injected Helix API hash
;;;
;;; The buffer-management functions in buffer.scm never call Helix directly;
;;; they read the primitives they need out of a context hash. This keeps the
;;; buffer logic testable and decoupled from any particular plugin. Build the
;;; hash once (on the main thread) and thread it through.

(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")

(provide make-helix-context)

;;@doc
;; Create a hash of Helix API functions consumed by the buffer helpers.
(define (make-helix-context)
  (hash 'editor-focus
    editor-focus
    'editor-mode
    editor-mode
    'editor->doc-id
    editor->doc-id
    'editor-document->language
    editor-document->language
    'editor->text
    editor->text
    'editor-doc-in-view?
    editor-doc-in-view?
    'editor-doc-exists?
    editor-doc-exists?
    'editor-set-focus!
    editor-set-focus!
    'editor-switch!
    editor-switch!
    'editor-set-mode!
    editor-set-mode!
    'helix.new
    helix.new
    'helix.vsplit
    helix.vsplit
    'helix.hsplit
    helix.hsplit
    'set-scratch-buffer-name!
    set-scratch-buffer-name!
    'helix.set-language
    helix.set-language
    'helix.static.select_all
    helix.static.select_all
    'helix.static.collapse_selection
    helix.static.collapse_selection
    'helix.static.insert_string
    helix.static.insert_string
    'helix.static.align_view_bottom
    helix.static.align_view_bottom))
