(in-package :tests)

(defparameter *tests* nil)

(defun run-tests ()
  "Runs all tests."
  (loop for test in *tests*
     for result = (handler-case (progn
				  (format t "Testing ~a ...~%" test)
				  (funcall test)) (simple-error (e) (warn "~a" e)))
     sum (if result 1 0) into passed sum 1 into total
     do (unless result (warn "The test ~a failed." test))
     finally (format t "~a of ~a tests passed." passed total)))

(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body t)
     (pushnew ',name *tests*)))

(deftest actors-list-do-search
  (let* ((actor (make-instance 'actor :name "Radcliffe, Daniel"))
	 (movie (make-instance 'movie :title "Harry Potter and the Chamber of Secrets"))
	 (results (do-search (make-list-instance 'actors) actor)))
    (assert (= (length results) 231))
    (assert (find (make-instance 'role :actor actor :movie movie) results :test #'role=))))

(deftest actors-list-inverse-search
  (let* ((actor (make-instance 'actor :name "Watson, Emma (II)"))
	 (movie (make-instance 'movie :title "Harry Potter and the Chamber of Secrets"))
	 (results (inverse-search (make-list-instance 'actresses) movie)))
    (assert (= (length results) 32))
    (assert (find (make-instance 'role :actor actor :movie movie) results :test #'role=))))

(deftest alternate-versions-list-do-search
  (let* ((movie (make-instance 'movie :title "Buffy the Vampire Slayer"))
	 (results (do-search (make-list-instance 'alternate-versions) movie))
	 (av (first results)))
    (assert (= (length results) 14))
    (assert (movie= movie (movie av)))
    (assert (null (episode av)))
    (assert (= (length (info av)) 3))
    (assert (equal (search "Since being" (first (info av))) 0))))

(deftest crazy-credits-list-do-search
  (let* ((movie (make-instance 'movie :title "Supernatural"))
	 (results (do-search (make-list-instance 'crazy-credits) movie))
	 (cc (first results)))
    (assert (= (length results) 18))
    (assert (movie= movie (movie cc)))
    (assert (null (episode cc)))
    (assert (= (length (info cc)) 2))
    (assert (equal (search "The logo" (first (info cc))) 0))))

(deftest goofs-list-do-search
  (let* ((movie (make-instance 'movie :title "Buffy the Vampire Slayer"))
	 (results (do-search (make-list-instance 'goofs) movie))
	 (goof (third results)))
    (assert (= (length results) 137))
    (assert (movie= movie (movie goof)))
    (assert (equal (episode goof) "Welcome to the Hellmouth (#1.1)"))
    (assert (= (length (info goof)) 6))
    (assert (equal (search "CHAR: In the first" (first (info goof))) 0))))

(deftest soundtracks-list-do-search
  (let* ((movie (make-instance 'movie :title "Game of Thrones"))
	 (results (do-search (make-list-instance 'soundtracks) movie))
	 (soundtracks (first results)))
    (assert (= (length results) 63))
    (assert (movie= movie (movie soundtracks)))
    (assert (null (episode soundtracks)))
    (assert (= (length (info soundtracks)) 1))
    (assert (equal (search "\"Main Title\"" (first (info soundtracks))) 0))))

(deftest trivia-list-do-search
  (let* ((movie (make-instance 'movie :title "Supernatural"))
	 (results (do-search (make-list-instance 'trivia) movie))
	 (trivia (first results)))
    (assert (= (length results) 254))
    (assert (movie= movie (movie trivia)))
    (assert (null (episode trivia)))
    (assert (= (length (info trivia)) 99))
    (assert (equal (search "SPOILER: Early on" (first (info trivia))) 0))))

(deftest quotes-list-do-search
  (let* ((movie (make-instance 'movie :title "Game of Thrones"))
	 (results (do-search (make-list-instance 'quotes) movie))
	 (quotes (first results)))
    (assert (= (length results) 61))
    (assert (movie= movie (movie quotes)))
    (assert (null (episode quotes)))
    (assert (= (length (info quotes)) 21))
    (assert (equal (search "[repeated line]" (first (info quotes))) 0))))

(deftest movies-list-suggest
  (let* ((results (suggest (make-list-instance 'movies) "Harry Potter")))
    (assert (find "Harry Potter and the Chamber of Secrets" results :test #'equal))
    (assert (find "Harry Potter and the Deathly Hallows: Part 1" results :test #'equal))))
