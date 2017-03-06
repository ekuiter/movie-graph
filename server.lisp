(in-package :server)

(defparameter +graph-path+ "assets/graph.svg")
(defvar *graph-classes* nil)
(defvar *node-filter* (graph:all-filter))
(defvar *edge-filter* (graph:all-filter))
(defvar *destructive-operation-running* nil)
(defvar *destructive-operation-progress* "")

(load-plugins)
(setf (cl-who:html-mode) :html5)

(defmacro defroute (options (bind-request bind-response &optional bind-args) &body body)
  `(wookie:defroute ,options (,bind-request ,bind-response args)
     (destructuring-bind ,bind-args args ,@body)))

(defun send-json-response (res json)
  (send-response res :headers '(:content-type "application/json")
		 :body (json:encode-json-to-string json)))

(defmacro defsearchroute (path function id-class-function)
  `(defroute (:get ,(format nil "/~a/(.+)/(.+)" path)) (req res (list-string id-string))
     (let* ((list (imdb:make-list-instance list-string))
	    (id-object (make-instance (,id-class-function list) :string id-string))
	    (results (,function list id-object)))
       (send-json-response res results))))

(defun redirect (res path)
  (send-response res :status 302 :headers (list :location path)))

(defmacro with-html-string (&body body)
  `(with-html-output-to-string (s nil :prologue t) ,@body))

(defmacro make-html (&body body)
  (let ((stylesheets (list "jquery-ui.min" "app"))
	(scripts (list "jquery.min" "jquery-ui.min" "helpers" "server" "filter"
		       "node-filter" "edge-filter" "graph-classes" "sidebar"
		       "progress" "app")))
    `(with-html-string
       (:html (:head (:title "movie-graph")
		     (:meta :charset "utf-8")
		     (:meta :name "viewport" :content "width=device-width, initial-scale=1")
		     ,@(mapcar (lambda (stylesheet)
				 `(:link :rel "stylesheet" :href
					 ,(format nil "assets/~a.css" stylesheet)))
			       stylesheets)
		     ,@(mapcar (lambda (script)
				 `(:script :src ,(format nil "assets/~a.js" script)))
			       scripts))
	      (:body ,@body)))))

(defun update-graph (&key (graph-classes *graph-classes*) (node-filter *node-filter*)
		       (edge-filter *edge-filter*) (body ""))
  (let ((graph (eval `(app:make-graph (app:current-graph) ,@graph-classes))))
    (setf graph (graph:filter-nodes graph node-filter)
	  graph (graph:filter-edges graph edge-filter)
	  *graph-classes* graph-classes *node-filter* node-filter *edge-filter* edge-filter)
    (app:make-image graph +graph-path+ :format "svg"))
  body)

(defmacro def-graph-route (options (bind-request bind-response &optional bind-args) &body body)
  `(defroute ,options (,bind-request ,bind-response ,bind-args)
     (let ((body (apply #'update-graph (progn ,@body))))
       (unless (eql body :none)
	 (send-response res :body body)))))

(defmacro def-destructive-graph-route (options (bind-request bind-response &optional bind-args)
				       &body body)
  `(def-graph-route ,options (,bind-request ,bind-response ,bind-args)
     (when *destructive-operation-running*
       (error "a destructive operation is already running"))
     ,@body))

(defun json-to-filter (json)
  (let ((*string* nil))
    (declare (special *string*))
    (flet ((beginning () (setf *string* (make-array 0 :fill-pointer 0
						    :adjustable t :element-type 'character)))
	   (parse-token (token) (vector-push-extend token *string*))
	   (end ()
	     (let ((string-upcase (string-upcase *string*)))
	       (if (search "-FILTER" string-upcase)
		   (or (find-symbol string-upcase :graph)
		       (find-symbol string-upcase :app)
		       (error "~a is not a filter" *string*))
		   *string*))))
      (json:bind-custom-vars
	  (:beginning-of-string #'beginning :string-char #'parse-token
				:end-of-string #'end :string-scope '(*string*))
	(let ((form (json:decode-json-from-string json)))
	  (values (eval form) form))))))

(defmacro def-filter-route (path keyword)
  `(def-graph-route (:get ,path) (req res (filter-json))
     (list ,keyword (json-to-filter filter-json))))

(defroute (:get "/") (req res)
  (let ((body (make-html
		(:div :id "wrapper"
		      (:div :id "sidebar-pad")
		      (:object :id "graph" :type "image/svg+xml")
		      (:div :id "empty-graph" (:p "Nothing here.")
			    (:p (:a :href "#" :class "add" "Add some movies")
				(:span :class "show" " or "
				       (:a :href "#" :class "all" "show them all")) ".")))
		(:div :id "sidebar"
		      (:ul :id "menu"
			   (:li :class "ui-widget-header" (:div "movie-graph"))
			   (:li :id "collapse"
				(:div (:span :class "ui-icon ui-icon-triangle-1-n")
				      (:span :class "text" "Hide")))
			   (:li :id "add"
				(:div (:span :class "ui-icon ui-icon-plusthick") "Add movies"))
			   (:li :id "clear"
				(:div (:span :class "ui-icon ui-icon-trash") "Clear graph"))
			   (:li :id "debug"
				(:div (:span :class "ui-icon ui-icon-wrench") "Debug"))
			   (:li :id "info"
				(:div (:span :class "ui-icon ui-icon-info") "Info")))
		      (:p (:b "Style"))
		      (:div :id "graph-classes")
		      (:p (:b "Movies"))
		      (:div :id "node-filter"
			    (:div :class "buttons"
			     (:button :class "all"
				      (:span :class "ui-icon ui-icon-circle-plus") " All")
			     (:button :class "none"
				      (:span :class "ui-icon ui-icon-circle-minus") " None"))
			    (:div :class "filters"))
		      (:p (:b "Actors"))
		      (:div :id "edge-filter"))
		(:div :id "info-dialog" :title "movie-graph"
		      (:p "movie-graph visualizes connections between movies using the IMDb.")
		      (:p "Visit on GitHub: " (:a :href "https://github.com/ekuiter/movie-graph"
						  "ekuiter/movie-graph"))
		      (:p "Information courtesy of IMDb ("
			  (:a :href "http://www.imdb.com" "imdb.com")
			  "). Used with permission."))
		(:div :id "error-dialog" :title "Error")
		(:div :id "add-dialog" :title "Add movies"
		      (:p "Enter some movie titles:")
		      (:input))
		(:div :id "clear-dialog" :title "Clear graph"
		      (:p "Do you really want to remove all movies?"))
		(:div :id "debug-dialog" :title "Debug"
		      (:p "Enter any Lisp form to evaluate on the server:")
		      (:input)
		      (:p :class "progress")
		      (:p :class "results"))
		(:div :id "progress-dialog" :title "Adding movies ..."
		      (:p :class "progress")))))
    (send-response res :headers '(:content-type "text/html; charset=utf-8") :body body)))

(defroute (:get "/graph/nodes/") (req res)
  (send-json-response res (graph:vertices (app:current-graph))))

(defroute (:get "/graph/edges/") (req res)
  (send-json-response res (graph:edges (app:current-graph))))

(def-destructive-graph-route (:get "/clear/") (req res)
  (app:clear-graph)
  nil)

(def-destructive-graph-route (:get "/add/(.*)") (req res (movies))
  (flet ((fn ()
	   (let ((stream (make-string-output-stream)))
	     (setf *destructive-operation-running* stream)
	     (unwind-protect (let ((*standard-output* *destructive-operation-running*))
			       (apply #'app:add-movies
				      (split-sequence #\/ movies :remove-empty-subseqs t)))
	       (setf *destructive-operation-running* nil
		     *destructive-operation-progress* "")
	       (close stream)))))
    (ccl:process-run-function "add-movies" #'fn))
  nil)

(defun calculate-progress (progress-string)
  (let ((percent (parse-integer
		  (first (last (cl-ppcre:all-matches-as-strings "\\d{2}|\\d" progress-string)))))
	(actresses (search "actresses" progress-string)))
    (+ (if actresses 50 0) (/ percent 2))))

(defroute (:get "/progress/") (req res)
  (let ((result
	 (if *destructive-operation-running*
	     (calculate-progress (setf *destructive-operation-progress*
				       (concatenate 'string *destructive-operation-progress*
						    (get-output-stream-string
						     *destructive-operation-running*))))
	     nil)))
    (send-json-response res result)))

(def-graph-route (:get "/update/(.*)") (req res (classes))
  (list :graph-classes (mapcar (lambda (class) (intern (string-upcase class) :app))
			       (split-sequence #\/ classes :remove-empty-subseqs t))))

(def-filter-route "/filter/node/(.*)" :node-filter)
(def-filter-route "/filter/edge/(.*)" :edge-filter)

(defsearchroute "search" imdb:do-search imdb:id-class)
(defsearchroute "inverse-search" imdb:inverse-search imdb:inverse-id-class)

(defroute (:get "/suggest/(.+)") (req res (title))
  (let* ((results (imdb:suggest (imdb:make-list-instance 'movies) title)))
    (send-json-response res results)))

(defroute (:get "/eval/(.+)") (req res (form))
  (send-json-response res (eval (read-from-string form))))

(def-directory-route "/assets" "./assets")

(defroute (:* ".+" :priority -1) (req res)
  (send-response res :body "Page not found." :status 404))

(defun serve (&optional (port 3000))
  (update-graph)
  (handler-bind
      ((cl-async:streamish-closed (lambda (c)
				    (declare (ignore c))
				    (invoke-restart 'cl-async::continue-event-loop))))
    (as:with-event-loop ()
      (let* ((listener (make-instance 'listener :bind "127.0.0.1" :port port))
	     (server (start-server listener)))
	(as:signal-handler 2 (lambda (sig)
			       (declare (ignore sig))
			       (as:free-signal-handler 2)
			       (as:close-tcp-server server)))))))
