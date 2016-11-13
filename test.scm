(use posix utils fmt fmt-color srfi-13)

;; util

(define (eq-length? n l)
  (eq? n (length l)))

(define (print-success str)
  (print (fmt #f (fmt-green str))))

(define (print-fail str)
  (print (fmt #f (fmt-red str))))

(define (asm-tree-to-str tree)
  (string-join (apply append
		      (map (lambda (n)
			     (list (conc (->string (car n)) " " (string-join (map ->string (cdr n)) ", "))))
			   (compile-program tree)))
	       "\n"))

;; init tests

(load "po.scm")
(system "mkdir -p /tmp/po_tests")
(system "cp driver.c /tmp/po_tests") ; move driver to working dir

(define (run-test expr cmp expect-val)
 (begin
   (display (conc
	      (string-pad-right (->string expr) 40)
	      (string-pad (string-upcase (symbol->string cmp)) 6) " "
	      (string-pad-right (->string expect-val) 5)))
   (with-output-to-file "/tmp/po_tests/scheme_entry.s"
     (lambda ()
       (print (asm-tree-to-str expr))))
   (system "cd /tmp/po_tests && cc -std=c99 -g -malign-double -m32 -o scheme_test scheme_entry.s driver.c")
   (let ((r (with-input-from-pipe "cd /tmp/po_tests && ./scheme_test" read)))
     (if (eval `(,cmp ,expect-val ,r)) ; TODO: use unhygenic macros instead...
       (print-success "SUCCESS")
       (begin
	 (print-fail "FAILED")
	 (print r " " cmp " " expect-val)
	 (print (read-all "/tmp/po_tests/scheme_entry.s"))
	 (exit 1))))))

(run-test '((lambda () 123))	'eq? 123)
(run-test 0			'eq? 0)
(run-test 3			'eq? 3)
(run-test -3			'eq? -3)
(run-test #\3			'eq? #\3)
(run-test #\a			'eq? #\a)
(run-test #\!			'eq? #\!)
(run-test #t			'eq? #t)
(run-test #f			'eq? #f)
(run-test '() 			'eq-length? 0)
(run-test `(zero? 0)		'eq? #t)
(run-test `(add1 0)		'eq? 1)
(run-test `(add1 -1)		'eq? 0)
(run-test `(add1 10)		'eq? 11)
(run-test `(sub1 10)		'eq? 9)
(run-test `(integer->char 65)	'eq? #\A)
(run-test `(char->integer #\A)	'eq? 65)
(run-test `(null? ,'())	'eq? #t)
(run-test `(null? 0)		'eq? #f)
(run-test `(null? #\a)		'eq? #f)
(run-test `(null? #t)		'eq? #f)
(run-test `(integer? #t)	'eq? #f)
(run-test `(integer? #\a)	'eq? #f)
(run-test `(integer? ,'())	'eq? #f)
(run-test `(integer? 45)	'eq? #t)
(run-test `(boolean? #t)	'eq? #t)
(run-test `(boolean? #f)	'eq? #t)
(run-test `(boolean? #\t)	'eq? #f)
(run-test `(boolean? ,'())	'eq? #f)
(run-test `(boolean? 31)	'eq? #f)
(run-test `(zero? 0)		'eq? #t)
(run-test `(zero? 4)		'eq? #f)
(run-test `(zero? -4)		'eq? #f)
(run-test `(+ 3 2)		'eq? 5)
(run-test `(+ 4 3 2)		'eq? 9)
(run-test `(+ 1 2 3 4 5 6)     'eq? 21)
(run-test `(+ (add1 1) 2)      'eq? 4)
(run-test `(+ (+ 1 2 3) 2)     'eq? 8)
(run-test `(- 3 2 1)		'eq? 0)
(run-test `(- 1 2 3)		'eq? -4)
(run-test `(let ((a 3))
	     a)		'eq? 3)
(run-test `(let ((a 3))
	     (add1 a))		'eq? 4)
(run-test `(let ((a 3) (b 1))
	     (+ a b))		'eq? 4)
(run-test `(if #t
	     2
	     3)		'eq? 2)
(run-test `(if #f
	     2
	     3)		'eq? 3)
(run-test `(if (zero? (+ 1 2 3 4))
	     #\<
	     #\>)		'eq? #\>)
(run-test `(if (zero? (+ 1 2 -1 -2))
	     #\<
	     #\>)		'eq? #\<)
(run-test `(if (eq? 1 2)
	     #\y
	     #\n)		'eq? #\n)
(run-test `(if (eq? (+ 1 1) 2)
	     #\y
	     #\n)		'eq? #\y)
(run-test `(car (cons (+ 1 3) 2))	'eq? 4)
(run-test `(cdr (cons (+ 1 3) 2))	'eq? 2)
(run-test `(let ((a (cons 10 20)))
	     (car a))			'eq? 10)
(run-test `(car (cons 1 (cons 1 ,'()))) 'eq? 1)
(run-test `(let ((a (cons 1 (cons 3 (cons 2 ,'())))))
	     (let ((b (cons 3 a)))
	       (car (cdr b))))		'eq? 1)
(run-test `(let ((a (cons 1 (cons 3 (cons 2 ,'())))))
	     (let ((b (cons 3 a)))
	       (car b)))		'eq? 3)
(run-test `(let ((a (cons 1 (cons 2 ,'()))))
	     (cdr (cdr a)))	'eq? '(quote ()))
(run-test `(vector-length (make-vector 2))		'eq? 2)
(run-test `(string-length (make-string 4))		'eq? 4)
(run-test `(string-set! (make-string 1) 0 #\B)	'equal? "B")
(run-test `(string-ref (string-set! (make-string 5) 4 #\A) 4)	'eq? #\A)
(run-test `(string-ref (string-set! (make-string 1) 0 #\B) 0)	'eq? #\B)
