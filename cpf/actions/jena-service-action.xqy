xquery version "1.0-ml";


import module namespace sem = "http://marklogic.com/semantics" 
      at "/MarkLogic/semantics.xqy";

(: Copyright 2002-2013 MarkLogic Corporation.  All Rights Reserved. :)

(:
:: State action to call jena wrapper service
:: 
:: This module 
:: a.  skolemizes incoming blank nodes in order to halt their proliferation
:: b.  Constructs a query to grab a subset of ontology triples for reasoning input.
:: c.  Filters the response for only triples that are new.
::
:: Uses the external variables:
::    $cpf:document-uri: The document being processed
::    $cpf:transition: The transition being executed
:)

declare namespace jena="/ext/actions/jena-service-action.xqy";

import module namespace cvt="http://marklogic.com/cpf/convert" 
   at "/MarkLogic/conversion/convert.xqy";
import module namespace cpf = "http://marklogic.com/cpf" 
   at "/MarkLogic/cpf/cpf.xqy";
import module namespace lnk = "http://marklogic.com/cpf/links" 
   at "/MarkLogic/cpf/links.xqy";

declare variable $default-graph-uri := "http://marklogic.com/semantics#default-graph";

declare variable $cpf:document-uri as xs:string external := "/test.txt";
declare variable $cpf:transition as node()* external := ();
declare variable $validation-query := '
       prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
       prefix owl: <http://www.w3.org/2002/07/owl#>
       CONSTRUCT {?s ?p ?o} 
       where { 
           ?s ?p ?o .
           ?o ?p2 ?o2 .
       filter (?p = rdfs:subClassOf &amp;&amp; ?o2 = owl:Restriction)}"
       ';
declare variable $ontology-query := '
       prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
       prefix owl: <http://www.w3.org/2002/07/owl#>
       CONSTRUCT {?s ?p ?o} where { ?s ?p ?o . ?o a ?o2
       filter (
           (?p = rdfs:subClassOf || 
            ?p = rdfs:subPropertyOf ||
            ?p = rdfs:domain ||
            ?p = rdfs:range ||
            ?p = owl:intersectionOf ||
            ?p = owl:unionOf ||
            ?p = owl:equivalentClass ||
            ?p = owl:equivalentProperty ||
            ?p = owl:inverseOf ||
            ?p = owl:hasValue || 
            ?o = owl:FunctionalProperty ||
            ?o = owl:InverseFunctionalProperty ||
            ?o = owl:SymmetricProperty ||
            ?o = owl:TransitiveProperty 
           ) &amp;&amp; ?o2 != owl:Restriction)
       }
       ';


declare function local:skolemize(
    $triples as sem:triple*
) as sem:triple*
{
    let $orig :=  "http://marklogic.com/semantics/blank"
    let $skolem := "http://marklogic.com/semantics/skolem"
    for $triple in $triples
    return
        sem:triple(
            sem:iri(replace(sem:triple-subject($triple), $orig, $skolem)),
            sem:iri(replace(sem:triple-predicate($triple), $orig, $skolem)),
            if (sem:isIRI(sem:triple-object($triple)))
            then sem:iri(replace(sem:triple-object($triple), $orig, $skolem))
            else sem:triple-object($triple)
        )
};


(: this function is supposed to remove all of the suprious
 : axiomatic triples that come back in every reasoning payload :)
declare function local:trim-results(
    $triples as sem:triple*,
    $subjects as sem:iri*
) as sem:triple*
{
    if (count($triples) eq 0)
    then ()
    else 
        let $filter := 
            string-join(
                for $subject in $subjects
                return 
                    concat("?s = <" , 
                        $subject , ">"),
                        " || ")
        (: let $_ := xdmp:log($filter) :)
        return
        sem:sparql-triples(
            concat(
                "construct {?s ?p ?o} where {?s ?p ?o. filter ( ", 
                $filter,
                ") }"), $triples)
};

(: remove all triples from LHS that are in RHS :)
declare function local:dedupe(
    $t1 as sem:triple*, $t2 as sem:triple*
) as sem:triple*
{
    let $m1 := map:new($t1 ! map:entry(string(sem:triple-hash(.)), .))
    let $m2 := map:new($t2 ! map:entry(string(sem:triple-hash(.)), .))
    let $m3 := $m1 - $m2
    return map:keys($m3) ! map:get($m3, .)
};

xdmp:log("REASONING BEGIN: " || $cpf:document-uri),
if (cpf:check-transition($cpf:document-uri,$cpf:transition)) 
then
try {
   let $ultimate-source := 
      fn:string((lnk:from( $cpf:document-uri )[@rel="source"]/@to)[1])
   let $source-uri := 
      if ( $ultimate-source = "" )
      then $cpf:document-uri
      else $ultimate-source
   let $explicit-triples := local:skolemize(sem:rdf-parse(doc($cpf:document-uri)/node(), "turtle"))
   let $subjects := sem:sparql-triples("select ?s where { ?s ?p ?o }",$explicit-triples) ! map:get(., "s")
   let $ontologies := 
       cts:search(
           /, 
           cts:triple-range-query( 
               (), 
               sem:iri("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"), 
               sem:iri("http://www.w3.org/2002/07/owl#Ontology")))/base-uri(.)
   let $ontology-turtles := 
       for $ontology in $ontologies
       return fn:string((lnk:from( $ontology )[@rel="source"]/@to)[1])
   let $is-ontology := sem:sparql-triples("prefix owl: <http://www.w3.org/2002/07/owl#> ASK WHERE { ?x a owl:Ontology }", $explicit-triples)
   let $destination-root := concat("/triples/", $source-uri)
   let $destination-uri := cvt:destination-uri( $destination-root, ".xml" )
   let $implicit-destination-uri := replace($destination-uri, "triples", "inferences")
   let $response :=
       (
       xdmp:http-post(
           concat("http://localhost:3000/jena?ontology=",
                  encode-for-uri($ontology-query)),
           <options xmlns="xdmp:http">
           </options>,
           doc($cpf:document-uri)/node()),
       if ($is-ontology)
       then 
           (xdmp:log(("Restarting reasoning on dependents of ", $cpf:document-uri)),
           (: TODO narrow those docs to queue :)
           for $instance-uri in ()
           return
               if (cpf:document-get-processing-status($instance-uri) eq "done")
               then 
                   (cpf:document-set-state($instance-uri, xs:anyURI("http://marklogic.com/states/ontology-updated")),
                   cpf:document-set-processing-status($instance-uri, "updated"))
               else ())
       else ()
       )
   let $results := $response[2]
   let $reasoned-triples := 
       if (exists($results/binary()))
       then ()
       else sem:rdf-parse($results, "turtle")
   let $trimmed-results := 
       local:trim-results($reasoned-triples, $subjects)
   let $implicit-triples :=
       local:dedupe($trimmed-results, $explicit-triples)
   let $graph-name := $source-uri
   return 
         let $permissions := xdmp:document-get-permissions($cpf:document-uri)
         let $collections := ($graph-name, $default-graph-uri)
         let $explicit-triples-doc := <triples>{$explicit-triples}</triples>
         return 
             (
                xdmp:document-insert( $destination-uri, $explicit-triples-doc, $permissions, ($collections, "explicit") ),
                lnk:create( $destination-uri, $cpf:document-uri, "source", "parse", "strong" ),
                if (exists($implicit-triples))
                then (
                    xdmp:document-insert( $implicit-destination-uri, <triples>{$implicit-triples}</triples>, $permissions, ($collections, "implicit")),
                      lnk:create( $implicit-destination-uri, $cpf:document-uri, "source", "inference", "strong" )
                      )
               else ()
             )
   , 
   cpf:success( $cpf:document-uri, $cpf:transition, () )
} 
catch ($e) {
    xdmp:log(("CPF ontology load pipeline failed", $e)),
   cpf:failure( $cpf:document-uri, $cpf:transition, $e, () )
}
else (),
xdmp:log("REASONING END: " || $cpf:document-uri)

