;; Copyright (C) 2026 Tom Waddington
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; buffer.scm - REPL scratch-buffer management
;;;
;;; Generic split/scratch-buffer handling for REPL-style plugins, factored out
;;; of nrepl.hx. A `repl-buffer` handle carries the target buffer name, split
;;; orientation, seed line and the current DocumentId (or #f). The ensure/append
;;; operations return a possibly-updated handle so callers can store the new id.
;;;
;;; All Helix interaction goes through the injected context hash from
;;; helix-context.scm; nothing here calls Helix directly.

(provide repl-buffer
  repl-buffer?
  repl-buffer-id
  repl-buffer-name
  repl-buffer-orientation
  repl-buffer-seed-line
  repl-buffer-language
  make-repl-buffer
  repl-buffer-set-id
  repl-buffer:ensure
  repl-buffer:create
  repl-buffer:append)

;; A REPL output buffer handle.
;;   id          - DocumentId of the buffer, or #f if not yet created / stale
;;   name        - scratch buffer name (e.g. "*nrepl*", "*hx-eval*")
;;   orientation - 'vsplit or 'hsplit
;;   seed-line   - initial content inserted on creation (already including the
;;                 language comment prefix and trailing newline)
;;   language    - language name forced on the buffer (e.g. "scheme"), or #f to
;;                 copy the source document's language
(struct repl-buffer (id name orientation seed-line language) #:transparent)

;;@doc
;; Construct a fresh handle with no backing buffer yet. language is a language
;; name to force (e.g. "scheme") or #f to copy the source document's language.
(define (make-repl-buffer name orientation seed-line language)
  (repl-buffer #f name orientation seed-line language))

;;@doc
;; Return a copy of the handle with a new (or cleared) buffer id.
(define (repl-buffer-set-id rb id)
  (repl-buffer id
    (repl-buffer-name rb)
    (repl-buffer-orientation rb)
    (repl-buffer-seed-line rb)
    (repl-buffer-language rb)))

;;@doc
;; Ensure the buffer exists and is visible, creating it if necessary.
;;
;; Parameters:
;;   rb            - repl-buffer handle
;;   helix-context - hash of Helix API functions (see helix-context.scm)
;;   on-success    - callback: (updated-rb) -> void
(define (repl-buffer:ensure rb helix-context on-success)
  (let ([buffer-id (repl-buffer-id rb)])
    (if (and buffer-id
         ((hash-get helix-context 'editor-doc-exists?) buffer-id)
         ((hash-get helix-context 'editor-doc-in-view?) buffer-id))
      ;; Handle points at a live, visible buffer.
      (on-success rb)
      ;; No id, buffer closed, or not visible - clear and (re)create.
      (let ([cleared (if buffer-id (repl-buffer-set-id rb #f) rb)])
        (repl-buffer:create cleared helix-context on-success)))))

;;@doc
;; Create the buffer in a split (orientation from the handle), seed it, restore
;; focus to the original view, then invoke on-success with the updated handle.
(define (repl-buffer:create rb helix-context on-success)
  (let ([original-focus ((hash-get helix-context 'editor-focus))]
        [editor->doc-id (hash-get helix-context 'editor->doc-id)])
    (let ([original-doc-id (editor->doc-id original-focus)]
          [editor-document->language (hash-get helix-context 'editor-document->language)])
      ;; A forced language on the handle wins; otherwise copy the source
      ;; document's language.
      (let ([language (or (repl-buffer-language rb)
                       (editor-document->language original-doc-id))]
            [orientation (repl-buffer-orientation rb)])
        ;; Create split based on orientation setting
        (if (eq? orientation 'hsplit)
          ((hash-get helix-context 'helix.hsplit))
          ((hash-get helix-context 'helix.vsplit)))
        ;; Create new scratch buffer (will be created in the split)
        ((hash-get helix-context 'helix.new))
        ;; Set the buffer name
        ((hash-get helix-context 'set-scratch-buffer-name!) (repl-buffer-name rb))
        ;; Set the buffer language for highlighting
        (when language
          ((hash-get helix-context 'helix.set-language) language))
        ;; Capture the new buffer id, seed content, restore focus
        (let ([buffer-id (editor->doc-id ((hash-get helix-context 'editor-focus)))])
          ((hash-get helix-context 'helix.static.insert_string) (repl-buffer-seed-line rb))
          ((hash-get helix-context 'editor-set-focus!) original-focus)
          (on-success (repl-buffer-set-id rb buffer-id)))))))

;;@doc
;; Append text to the buffer, restoring focus/mode afterwards.
;;
;; Checks the buffer is still valid and visible; clears the id from the returned
;; handle if not. Returns the (possibly updated) handle.
(define (repl-buffer:append rb text helix-context)
  (let ([buffer-id (repl-buffer-id rb)])
    (if (not buffer-id)
      ;; No buffer id - nothing to do.
      rb
      ;; Buffer closed - clear the id.
      (if (not ((hash-get helix-context 'editor-doc-exists?) buffer-id))
        (repl-buffer-set-id rb #f)
        ;; Buffer exists - is it visible?
        (let ([maybe-view-id ((hash-get helix-context 'editor-doc-in-view?) buffer-id)])
          (if maybe-view-id
            ;; Visible - append. Save focus/mode before the try block so the
            ;; handler can always restore them.
            (let ([original-focus ((hash-get helix-context 'editor-focus))]
                  [original-mode ((hash-get helix-context 'editor-mode))])
              (with-handler (lambda (err)
                             ((hash-get helix-context 'editor-set-focus!) original-focus)
                             ((hash-get helix-context 'editor-set-mode!) original-mode)
                             (repl-buffer-set-id rb #f))
                (begin
                  ;; Focus the view containing the buffer
                  ((hash-get helix-context 'editor-set-focus!) maybe-view-id)
                  ;; Move to end of file: select all then collapse to end
                  ((hash-get helix-context 'helix.static.select_all))
                  ((hash-get helix-context 'helix.static.collapse_selection))
                  ;; Insert the text
                  ((hash-get helix-context 'helix.static.insert_string) text)
                  ;; Scroll to show the newly inserted text
                  ((hash-get helix-context 'helix.static.align_view_bottom))
                  ;; Restore original focus and mode
                  ((hash-get helix-context 'editor-set-focus!) original-focus)
                  ((hash-get helix-context 'editor-set-mode!) original-mode)
                  rb)))
            ;; Not visible - clear id so it is recreated on next append
            (repl-buffer-set-id rb #f)))))))
