#lang racket/base
(require racket/string
         racket/file
         racket/list
         racket/format
         racket/match
         struct-define
         lux
         lux/chaos/gui
         lux/chaos/gui/key
         lux/chaos/gui/val
         pict)

(define config-p (build-path (find-system-path 'home-dir) ".config" "reed"))

;; ebook-convert .pub .txt --txt-output-formatting=markdown
;; # Chapter
;; *italic*
;; **bold** 

;; add pause on pauses, like "," "." "-", etc

;; draw with pict

;; https://github.com/octobanana/fltrdr

;; https://en.wikipedia.org/wiki/Rapid_serial_visual_presentation

;; X frames   1 minute        W words    1 frame 
;; -------- = ---------- x ---------- x  -------
;; 1 second   60 seconds    1  minute    1 word
;;
;; X = 20 fps at 1200 WPM
;; X = 10 fps at  600 WPM
;; X =  5 fps at  300 WPM

(module+ main
  (require racket/cmdline)
  (command-line
   #:program "rsvp"
   #:args (p)
   (call-with-chaos
    (make-gui)
    (λ () (rsvp p)))
   (void)))
