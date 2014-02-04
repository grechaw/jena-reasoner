(ns jena-reasoner.jena
  (:import (com.hp.hpl.jena.rdf.model ModelFactory Model)
           (com.hp.hpl.jena.reasoner ReasonerRegistry)
           (com.hp.hpl.jena.reasoner.rulesys RDFSRuleReasonerFactory OWLMicroReasonerFactory OWLMiniReasonerFactory)
           (java.util EnumSet NoSuchElementException)
           (java.io ByteArrayOutputStream ByteArrayInputStream)))

(defn hello [] "Hello from Jena")


(defn reason
  "Use jena to reason on triples.  Provide either
  instance adta in a stream, or an ontology stream and instance data as separate args"
  ([ontology-data instance-data]
  (let [reasoner (.create (OWLMicroReasonerFactory/theInstance) nil)
        emptyModel (ModelFactory/createDefaultModel)
        model (ModelFactory/createInfModel reasoner emptyModel)
        model (.read model ontology-data "" "TURTLE")
        model (.read model instance-data "" "TURTLE")]
    model)))

(defn validate [model]
  (let [validity (.validate model)]
    (if (.isValid validity)
      "OK"
      (map print (iterator-seq (.getReports validity))))))

(defn turtle-output
  [model baos]
  (.write model baos "TURTLE"))

(defn model-to-turtle
  [model]
  (let [baos (ByteArrayOutputStream.)
      writeit (turtle-output model baos)]
    (str baos)))
