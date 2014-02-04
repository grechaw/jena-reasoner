(ns jena-reasoner.jena-test
  (:use clojure.test
        jena-reasoner.jena
        jena-reasoner.marklogic
        clojure.pprint
        clojure.java.io)
  (:require [clojure.string :as string])
  (:import [java.net URLEncoder]))

(defn jena-fixture [f]
  (print "start")
  (put-turtle "ftcontent.ttl" (slurp "resources/ontology/ftcontent.ttl"))
  (f)
  (print "done")
  )

(def sample "file:resources/ontology/sample/content-sample-one.ttl")
(def ont "file:resources/ontology/ftcontent.ttl")

(use-fixtures :once jena-fixture)

(defn ontology-data []
  (sparql-construct "construct { ?s ?p ?o }  from <ontologies> where { ?s ?p ?o }"))

(deftest turtle-to-turtle-test
  (testing "jena makes turtle"
    (is (let [output (model-to-turtle (reason (input-stream (.getBytes (ontology-data))) (input-stream sample)))]
          (spit "target/test_reasoned.ttl" output)
          (.contains output "rNews:headline \"Royal Mail shares soar on first day of trading\"")))))

