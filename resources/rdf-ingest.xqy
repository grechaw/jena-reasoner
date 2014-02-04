xquery version "1.0-ml";

(:~
 : Ingestion transform for turtle or rdfxml to MarkLogic RDF
 : @author Charles Greer
 :)

module namespace rdf-ingest = "http://marklogic.com/rest-api/transform/rdf-ingest";
declare namespace html = "http://www.w3.org/1999/xhtml";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function rdf-ingest:transform(
  $context as map:map,
  $params as map:map,
  $content as document-node())
as document-node() {
    let $rdf := $content/node()
    let $triples := 
        typeswitch ($rdf) 
        case element() return sem:rdf-parse($rdf)
        default return sem:rdf-parse($rdf, "turtle")
    return document {
        element sem:triples {
            $triples
        }
    }
};
