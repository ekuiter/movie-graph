(in-package :tmdb)

(defparameter +api-key+ "f195f3a48ebe70b0d00e57fd5add98a2")
(defvar *configuration* nil)
(defvar *genres* nil)

(defun fetch-json-response (url &optional params)
  (let ((json:*json-identifier-name-to-lisp* #'string-upcase))
    (handler-case (json:decode-json-from-string
		   (flexi-streams:octets-to-string
		    (drakma:http-request url :parameters params) :external-format :utf-8))
      (error () nil))))

(defun call-api (method &optional params)
  (format t "Calling TMDb API method ~a~@[ and params ~a~]~%" method params)
  (setf params (acons :api_key +api-key+ params))
  (setf params (loop for (key . value) in params append
		    (acons (format nil "~(~a~)" key) value nil)))
  (let ((url (format nil "https://api.themoviedb.org/3/~a" method)))
    (fetch-json-response url params)))

(defun value (alist-or-obj path)
  (let ((single-value
	 (if (listp alist-or-obj)
	     (lambda (alist key) (cdr (assoc (intern key :keyword) alist)))
	     (lambda (obj key)
	       (slot-value obj (intern
				(json:camel-case-to-lisp (string-downcase key)) :keyword))))))
    (setf path (cl-ppcre:regex-replace-all "-" (format nil "~a" path) "_"))
    (let ((keys (split-sequence #\. path)))
      (loop for key in keys
	 for new-alist-or-obj = (funcall single-value alist-or-obj key)
	 then (funcall single-value new-alist-or-obj key)
	 finally (return new-alist-or-obj)))))

(defun load-configuration ()
  (setf *configuration*
	(or *configuration*
	    (if (probe-file "tmdb-configuration.dat")
		(with-open-file (stream "tmdb-configuration.dat") (read stream))
		(let ((configuration (call-api "configuration")))
		  (unless configuration (return-from load-configuration))
		  (with-open-file (stream "tmdb-configuration.dat" :direction :output)
		    (print configuration stream)))))))

(defun load-genres ()
  (setf *genres*
	(or *genres*
	    (if (probe-file "tmdb-genres.dat")
		(with-open-file (stream "tmdb-genres.dat") (read stream))
		(let* ((movie-genres (value (call-api "genre/movie/list") :genres))
		       (series-genres (value (call-api "genre/tv/list") :genres))
		       (genres (union series-genres movie-genres
				      :key (lambda (genre) (value genre :id)))))
		  (unless genres (return-from load-genres))
		  (with-open-file (stream "tmdb-genres.dat" :direction :output)
		    (print genres stream)))))))

(defun load-data ()
  (load-configuration)
  (load-genres)
  (not (not (and *configuration* *genres*))))

(defmethod data ((movie imdb:movie))
  (with-slots (imdb:tmdb-data) movie
    (when (slot-boundp movie 'imdb:tmdb-data)
      (return-from data imdb:tmdb-data))
    (let* ((method (format nil "search/~a"
			   (cond ((eql (imdb:type movie) :movie) "movie")
				 ((eql (imdb:type movie) :series) "tv")
				 (t (error "the given movie has no type")))))
	   (params (acons :query (imdb:title movie) nil))
	   (response (call-api method params))
	   (results (value response :results)))
      (setf imdb:tmdb-data (when results (first results))))))

(defun image-url (path &optional (size "original"))
  (let* ((configuration (load-configuration)))
    (format nil "~a~a~a" (value configuration :images.base-url) size path)))

(defmethod poster-url ((movie imdb:movie) &optional (size "original"))
  (when (data movie)
    (image-url (value (data movie) :poster-path) size)))

(defmethod genres ((movie imdb:movie))
  (when (data movie)
    (mapcar (lambda (genre-id)
	      (value (find genre-id (load-genres) :key (lambda (genre) (value genre :id))) :name))
	    (value (data movie) :genre-ids))))

(defmethod plot ((movie imdb:movie))
  (when (data movie)
    (value (data movie) :overview)))
