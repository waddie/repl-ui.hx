;; Copyright (C) 2026 Tom Waddington
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; cog.scm - Forge package manifest for repl-ui.hx
;;;
;;; Shared Helix/Steel machinery for REPL-style plugins: scratch-buffer
;;; management, evaluation-result formatting, an eval counter, rope coordinate
;;; conversion, selection/buffer text extraction, and the injected Helix-API
;;; context hash. Pure Scheme, no dylib.
;;;
;;; Installable with Steel's package manager:
;;;
;;;   forge pkg install --git https://github.com/waddie/repl-ui.hx
;;;
;;; then require the modules you need, e.g.:
;;;
;;;   (require "repl-ui.hx/buffer.scm")
;;;   (require "repl-ui.hx/format.scm")

(define package-name 'repl-ui.hx)
(define version "0.2.0")
(define dependencies '())
