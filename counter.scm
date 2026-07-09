;; Copyright (C) 2026 Tom Waddington
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; counter.scm - Per-session evaluation counter
;;;
;;; Mirrors the `repl:N:>` numbering of an interactive REPL. Instance-based so
;;; each plugin (or session) owns its own counter rather than sharing a global.

(provide make-eval-counter
  eval-counter-next!
  eval-counter-reset!)

;;@doc
;; Create a fresh eval counter (first eval will be numbered 1).
(define (make-eval-counter)
  (box 0))

;;@doc
;; Advance the counter and return the new value (first eval is 1).
(define (eval-counter-next! counter)
  (let ([n (+ 1 (unbox counter))])
    (set-box! counter n)
    n))

;;@doc
;; Reset the counter to 0 (next eval will be numbered 1).
(define (eval-counter-reset! counter)
  (set-box! counter 0))
