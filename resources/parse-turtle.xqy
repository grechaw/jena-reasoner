xquery version "1.0-ml";

(:~
 : Ingestion transform for turtle to MarkLogic RDF
 : @author Charles Greer
 :)

module namespace turtle-ingest = "http://marklogic.com/rest-api/transform/turtle-ingest";
declare namespace html = "http://www.w3.org/1999/xhtml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function turtle-ingest:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node())
as document-node() {
    let $turtle := $content/node()
    let $triples := sem:rdf-parse($turtle, "turtle")
    return document {
        element sem:triples {
            $triples
        }
    }
};
