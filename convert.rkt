#lang racket/base
(require racket/pretty
         racket/match
         racket/list
         racket/dict
         xml)

(define (go! p)
  (define x (with-input-from-file p read-xml/element))
  (define xe (xml->xexpr x))
  (match-define `(opml ([version "1.1"]) (head . ,_)
                       (body () . ,os)) xe)
  (define (process! os)
    (for ([o (in-list os)])
      (match o
        [`(outline ,ps)
         (displayln (first (dict-ref ps 'xmlUrl)))]
        [`(outline ([text ,_] [title ,_]) . ,os)
         (process! os)])))
  (process! os))

(module+ main
  (require racket/cmdline)
  (command-line #:program "convert"
                #:args (p)
                (go! p)))
