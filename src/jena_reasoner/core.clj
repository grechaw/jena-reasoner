(ns jena-reasoner.core
  (:use [clojure.java.io])
  (:require [jena-reasoner.jena :as jena]
            [jena-reasoner.marklogic :as marklogic]
            [clojure.string :as string])
  (:import [java.net URLEncoder]
           [org.slf4j Logger LoggerFactory]))

(def logger (LoggerFactory/getLogger "jena-reasoner"))

(defn get-ontology [query]
  (.info logger (str "Getting ontology with: " query))
  (let [ontology-turtle (marklogic/sparql-construct query)]
    (input-stream (.getBytes ontology-turtle))))

(defn run-jena [request]
  (let [is (:body request)
        params (:query-params request)
        ontology (get-ontology (params "ontology"))]
    (print ontology)
    {:status 200
     :headers {"Content-Type" "text/turtle"}
     :body (jena/model-to-turtle (jena/reason ontology is))}))


(defn handler
  [request]
  (print "Handling reasoning request")
  (let [first-step (second (string/split (:uri request) #"/"))]
    (if (= first-step "jena") 
      (run-jena request)
      {:status 404
       :headers {"Content-Type" "text/html"}
       :body "Don't know what to do with that"})))

