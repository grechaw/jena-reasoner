; this test installs a document, queries for no inference 

(ns jena-reasoner.integration-test
  (:use [jena-reasoner.marklogic]
        [clojure.pprint]))



(def prefixes "prefix : <http://marklogic.com/example/>")



(def stated-inferred ["where {:me a :Student}" "where {:me a :Person}"])
(def explicit-facet ["" "FROM <explicit>" "FROM <implicit>"])

(def queries 
  (for [query stated-inferred
        source explicit-facet]
    (str prefixes " ASK " source " " query)))

(pprint queries)

(defn exec
  [query]
  (json-body (sparql query)))

(put-turtle "i1.ttl" (slurp "test/resources/i1.ttl"))

(put-turtle "o1.ttl" (slurp "test/resources/o1.ttl"))


(map exec queries)


; property tests
(put-turtle "i2.ttl" (slurp "test/resources/i2.ttl"))

(put-turtle "o2.ttl" (slurp "test/resources/o2.ttl"))

(json-body (sparql "prefix : <http://marklogic.com/example/> ASK where {:gate1 a :Application}"))


(put-article "article1.xml" (slurp "test/resources/article1.xml"))
