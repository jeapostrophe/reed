#lang racket/base
(require racket/match
         racket/list
         racket/file
         racket/async-channel
         job-queue
         net/url
         xml
         raart)

(define config-p (build-path (find-system-path 'home-dir) ".config" "reed"))
(define (f-or-not p f d) (if (file-exists? p) (f p) d))
(define subs (f-or-not (build-path config-p "subscriptions.txt") file->lines '()))

(define sub->last-p (build-path config-p "last.rktd"))
(define sub->last (box (f-or-not sub->last-p file->value (hasheq))))
(define last-lock (make-semaphore 1))
(define (remember-last! s l)
  (call-with-semaphore
   last-lock
   (λ ()
     (define n (hash-set (unbox sub->last) s l))
     (set-box! sub->last n)
     (write-to-file n sub->last-p #:exists 'replace))))

;; XXX youtube

(struct li (sub title desc link guid) #:transparent)
(define the-feed (make-async-channel))

(define (parse! add! s)
  (define-values (status hs out) (http-sendrecv/url (string->url s)))
  (define xe (xml->xexpr (document-element (read-xml/document out))))  
  (match-define (list* 'rss r-ps rbody) xe)
  (match-define (list _ ... (list* 'channel ch-ps cbody) _ ...) rbody)
  (for/or ([x (in-list cbody)])
    (match x
      [(list* 'item ips ibody)
       (define (weak-assq k)
         (for/or ([b (in-list ibody)])
           (match b
             [(list* (== k) _ val) val]
             [_ #f])))
       (add!
        (li s (weak-assq 'title)
            (weak-assq 'description)
            (first (weak-assq 'link))
            (first (weak-assq 'guid))))]
      [_ #f]))
  (exit 1))
(define (update! s)
  (define l (hash-ref (unbox sub->last) s #f))
  (define new-l? #f)
  (define (add! i)
    (define g (li-guid i))
    (unless new-l?
      (set! new-l? #t)
      (remember-last! s g))
    (cond
      [(equal? l g) #t]
      [else
       (async-channel-put the-feed i)]))
  (parse! add! s)
  
  (exit 1))
(define jq (make-job-queue 1)) ;; XXX
(for ([s (in-list subs)])
  (submit-job! jq (λ () (update! s))))
(stop-job-queue! jq)
(async-channel-put the-feed #f)

(module+ main
  ;; XXX
  )
