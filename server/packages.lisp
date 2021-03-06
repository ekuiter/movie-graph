(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :split-sequence)
  (ql:quickload :cl-ppcre)
  (ql:quickload :wookie)
  (ql:quickload :cl-json)
  (ql:quickload :cl-who)
  (ql:quickload :drakma)
  (ql:quickload :lquery))

(defpackage :json-helpers
  (:use :common-lisp :cl-json)
  (:export :bypass-initialization :encode-with-prototype :encode-hash-table-with-prototype
	   :make-decodable :to-form :json-hash-table :decode-object-from-string
	   :allocate-and-populate-instance :build-object :bindings))

(defpackage :imdb
  (:use :common-lisp :split-sequence)
  (:export :actor :movie :role :actors-list :actresses-list :do-search :inverse-search
	   :name :readable-name :title :billing :actor= :actor< :movie=
	   :role-score :role= :role< :alternate-versions-list :make-list-instance
	   :alternate-versions :episode :info :summary :summarize :summarize-all
	   :goofs-list :goofs :trivia-list :trivia :crazy-credits :crazy-credits-list
	   :soundtracks :soundtracks-list :quotes :quotes-list :record-class :id-class
	   :inverse-id-class :movies-list :suggest :first-name :last-name :number
	   :type :year :movie-record :episode-score :readable-actor= :readable-actor<)
  (:shadow :file-length))

(defpackage :tmdb
  (:use :common-lisp :split-sequence :json-helpers)
  (:export :metadata :poster-url :genres :plot :setup :profile-url))

(defpackage :synchronkartei
  (:use :common-lisp)
  (:export :dubbed-movie :voice-actor :dubbed-role :suggest :voice-actors :role :path))

(defpackage :graph
  (:use :common-lisp)
  (:export :graph :node :edge :node-1 :node-2 :add-node :add-edge :make-image :subgraph
	   :make-image :show :to-dot :compare :label :vertices :edges :label-too-long-error
	   :filter-nodes :filter-edges :deffilter :and-filter :or-filter :not-filter :all-filter
	   :*filter-mode*))

(defpackage :app
  (:use :common-lisp :imdb :graph)
  (:export :to-dot :make-image :show :current-graph :clear-graph :add-movies :save-and-quit
	   :make-graph :encode-graph :restore-graph :*encoding-vertices* :*encoding-edges*
	   :find-movie :actors :actresses :voice-actors :movie-node :add-voice-actors))

(defpackage :tests
  (:use :common-lisp :imdb)
  (:export :run-tests))

(defpackage :server
  (:use :common-lisp :split-sequence :wookie :wookie-plugin-export :cl-who)
  (:export :serve)
  (:shadow :defroute))

(load "json-helpers")
(load "imdb")
(load "notes-list")
(load "actors-list")
(load "movies-list")
(load "tmdb")
(load "synchronkartei")
(load "graph")
(load "app")
(load "tests")
(load "server")
