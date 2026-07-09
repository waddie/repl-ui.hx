;; Copyright (C) 2026 Tom Waddington
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; coords.scm - Rope coordinate conversion

(require-builtin helix/core/text as text.)

(provide char-offset->line-col)

;;@doc
;; Convert a rope character offset to 1-indexed (line . column).
;;
;; Parameters:
;;   rope   - Helix rope/text object
;;   offset - Character offset (0-indexed)
;;
;; Returns: (line . column) pair, both 1-indexed.
;;
;; Example:
;;   (char-offset->line-col rope 42) => (3 . 10)
(define (char-offset->line-col rope offset)
  ;; Iterate through lines to find which line contains the offset
  (define (find-line-and-col line-idx char-pos)
    (if (>= line-idx (text.rope-len-lines rope))
      ;; Past end of rope - return last line
      (cons (text.rope-len-lines rope) 1)
      ;; Get the line text and calculate its length (including newline)
      (let* ([line-text (text.rope->line rope line-idx)]
             [line-len (text.rope-len-chars line-text)])
        (if (< offset (+ char-pos line-len))
          ;; Found the line containing the offset
          (let ([line-num (+ line-idx 1)] ; Convert to 1-indexed
                [col-num (+ (- offset char-pos) 1)]) ; 1-indexed column
            (cons line-num col-num))
          ;; Continue to next line
          (find-line-and-col (+ line-idx 1) (+ char-pos line-len))))))
  (find-line-and-col 0 0))
