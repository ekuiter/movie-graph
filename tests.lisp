(in-package :tests)

(defparameter *tests* nil)

(defun run-tests ()
  "Runs all tests."
  (loop for test in *tests*
     for result = (handler-case (funcall test) (simple-error (e) (warn "~a" e)))
     sum (if result 1 0) into passed
     sum 1 into total
     do
       (unless result
	 (warn "The test ~a failed." test))
     finally
       (format t "~a of ~a tests passed." passed total)))

(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body t)
     (pushnew ',name *tests*)))

(deftest actors-list-do-search
  (let* ((actor (make-instance 'actor :name "Radcliffe, Daniel"))
	 (movie (make-instance 'movie :title "Harry Potter and the Chamber of Secrets"))
	 (results (do-search (make-list-instance actors) actor)))
    (assert (= (length results) 231))
    (assert (find (make-instance 'role :actor actor :movie movie) results :test #'role=))))

(deftest actors-list-inverse-search
  (let* ((actor (make-instance 'actor :name "Watson, Emma (II)"))
	 (movie (make-instance 'movie :title "Harry Potter and the Chamber of Secrets"))
	 (results (inverse-search (make-list-instance actors "actresses") movie)))
    (assert (= (length results) 32))
    (assert (find (make-instance 'role :actor actor :movie movie) results :test #'role=))))

(deftest alternate-versions-list-do-search
  (let* ((movie (make-instance 'movie :title "Buffy the Vampire Slayer"))
	 (results (do-search (make-list-instance alternate-versions) movie))
	 (av (first results)))
    (assert (= (length results) 14))
    (assert (movie= movie (movie av)))
    (assert (null (episode av)))
    (assert (= (length (notes av)) 3))
    (assert (= (search "Since being" (first (notes av))) 0))))