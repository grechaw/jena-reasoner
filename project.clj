(defproject jena-reasoner "0.1.0-SNAPSHOT"
  :description "Web service wrapper for a Jena RDFS reasoner"
  :url "http://github.com/grechaw"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [org.clojure/data.json "0.2.3"]
                 [clj-http "0.7.6"]
                 [ring/ring-core "1.2.0"]
                 [ring/ring-jetty-adapter "1.2.0"]
                 [org.apache.jena/jena-core "2.7.4"]]
  :main jena-reasoner.service-runner)
