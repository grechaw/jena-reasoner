(ns jena-reasoner.marklogic
  (:use [clojure.stacktrace])
  (:require [clj-http.client :as client]
            [clojure.data.json :as json]
            [clojure.string :as string]))

(def docs-url "http://localhost:7001/v1/documents")
(def graphs-url "http://localhost:7001/v1/graphs")
(def sparql-url "http://localhost:7001/v1/graphs/sparql")

(defn sparql
  [query]
  (try
    (client/post sparql-url
                 {:digest-auth ["admin" "admin"]
                  :body query
                  :headers {"content-type" "text/plain"
                            "accept" "application/sparql-results+json"}})
    (catch Exception e (str e))))

(defn sparql-construct
  [query]
  (try
    (:body
      (client/post sparql-url
                   {:digest-auth ["admin" "admin"]
                    :body query
                    :headers {"content-type" "text/plain"
                              "accept" "text/turtle"}}))
    (catch Exception e (str e))))

(defn run-sparql
  [resource-url]
  (sparql (slurp resource-url)))

(defn json-body
  [response]
  (json/read-str (:body response) :key-fn keyword))


(defn put-turtle
  [name turtle-string]
  (let [uri name]
    (try
      (client/put docs-url
                  {:digest-auth ["admin" "admin"]
                   :body turtle-string
                   :query-params { "uri" uri
                                  "collection" "ingest" }
                   :headers {"content-type" "text/turtle"}})
      (catch Exception e (str e)))))

(defn put-article
  [name article-string]
  (let [uri name]
    (try
      (client/put docs-url
                  {:digest-auth ["admin" "admin"]
                   :body article-string
                   :query-params { "uri" uri
                                  "collection" "articles" }
                   :headers {"content-type" "application/xml"}})
      (catch Exception e (str e)))))


