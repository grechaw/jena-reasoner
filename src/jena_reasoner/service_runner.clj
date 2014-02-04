(ns jena-reasoner.service-runner
  (:gen-class)
  (:require [ring.adapter.jetty :as jetty]
            [ring.middleware.params :as m]
            [jena-reasoner.core :as core]))


(defn -main 
  [& args]
  (jetty/run-jetty (m/wrap-params core/handler) {:port 3000}))


