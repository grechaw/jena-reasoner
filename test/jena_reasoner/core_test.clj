(ns jena-reasoner.core-test
  (:use clojure.test
        clojure.java.io
        jena-reasoner.core)
  (:import [java.io File]))

(def ont (File. "resources/ontology/ftcontent.ttl"))
(def article (File. "test/resources/article1.xml"))

(deftest a-test
  (testing "jena says hello"
    (is (.contains (:body (run-jena {:query-params {"ontology" "prefix owl: <http://www.w3.org/2002/07/owl#> construct {?s ?p ?o} where {?s a owl:Ontology}"} :body (input-stream ont)})) "@prefix dc:"))))

