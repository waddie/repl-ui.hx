;; Copyright (C) 2026 Tom Waddington
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; selection.scm - Selection and buffer text extraction
;;;
;;; Pull evaluable text (and its source location) out of the focused document.
;;; Each extractor returns a hash with keys 'code (trimmed string), 'file-path,
;;; 'line and 'col (1-indexed), so callers that care about location (nrepl.hx)
;;; and callers that only need the code (eval.hx) share one API.

(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")
(require-builtin helix/core/text as text.)
(require "coords.scm")

(provide selection:primary
  selection:buffer
  selection:ranges)

;;@doc
;; Extract the primary selection.
;;
;; Returns a hash with 'code (trimmed), 'file-path, 'line, 'col, or #f when
;; nothing is selected (or the selection is whitespace-only).
(define (selection:primary)
  (let* ([code (helix.static.current-highlighted-text!)]
         [trimmed (if code (trim code) "")])
    (if (or (not code) (string=? trimmed ""))
      #f
      (let* ([focus (editor-focus)]
             [doc-id (editor->doc-id focus)]
             [file-path (editor-document->path doc-id)]
             [selection-obj (helix.static.current-selection-object)]
             [ranges (helix.static.selection->ranges selection-obj)]
             [primary-range (car ranges)]
             [cursor-pos (helix.static.range->from primary-range)]
             [rope (editor->text doc-id)]
             [line-col (char-offset->line-col rope cursor-pos)])
        (hash 'code trimmed
          'file-path
          file-path
          'line
          (car line-col)
          'col
          (cdr line-col))))))

;;@doc
;; Extract the entire focused buffer.
;;
;; Returns a hash with 'code (trimmed), 'file-path, and 'line/'col fixed at 1,
;; or #f when the buffer is empty.
(define (selection:buffer)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)]
         [code (text.rope->string (editor->text focus-doc-id))]
         [trimmed (if code (trim code) "")]
         [file-path (editor-document->path focus-doc-id)])
    (if (or (not code) (string=? trimmed ""))
      #f
      (hash 'code trimmed
        'file-path
        file-path
        'line
        1
        'col
        1))))

;;@doc
;; Extract every selection range in order.
;;
;; Returns a list of hashes (one per range) with 'code (trimmed), 'file-path,
;; 'line, 'col. Empty/whitespace-only ranges are preserved with 'code = "" so
;; callers can decide whether to skip them.
(define (selection:ranges)
  (let* ([selection-obj (helix.static.current-selection-object)]
         [ranges (helix.static.selection->ranges selection-obj)]
         [focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)]
         [rope (editor->text focus-doc-id)]
         [file-path (editor-document->path focus-doc-id)])
    (map (lambda (range)
          (let* ([from (helix.static.range->from range)]
                 [to (helix.static.range->to range)]
                 [code (text.rope->string (text.rope->slice rope from to))]
                 [trimmed (trim code)]
                 [line-col (char-offset->line-col rope from)])
            (hash 'code trimmed
              'file-path
              file-path
              'line
              (car line-col)
              'col
              (cdr line-col))))
      ranges)))
