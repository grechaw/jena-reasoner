# jena-reasoner

This project contains a clojure project and MarkLogic Server that supports a basic inferencing scenario, in which a customer relies on materialized inferences for their data architecture.

The clojure app is a standalone web server that wraps a reasoner and an ontology-based annotator.

## Requires Java 7 JDK

## Initial MarkLogic Setup

1. After installation navigate to http://localhost:8000/appservices
2. Click "New Database".  Name it jena-poc.
3. Click the newly activated "configure" button.  (Sometimes this page require a hard refresh in firefox)
4. Enable the collection lexicon and "Semantics", and then Add a REST API Instance called jena-poc on port 7001.
5. Click "Admin" in the nav header to go the RED GUI for CPF configuration.

6. Turn off security for the appserver -- Integrations require no-auth SPARQL.  So for the jena-poc appserver, set "application level" and "Admin" for security.

## CPF configuration
CPF is a gsreat tool for managing documents that need processing through a series of states.  This PoC uses CPF to manage documents on their way through the reasoning and annotation pipelines.

1. Find the jena-poc database under "Databases"
2. In the made config page for this database, select the "Triggers" database as its "Triggers Database".
2. Select "Content Processing" in the left nav, and install CPF (without conversion)
3. Click on the new "Default jena-poc" Domain.  Set the domain-scope to "collection" and uri to "ingest".  Set the "evaluation context->modules" to "jena-poc-modules"
5. under pipelines select the "Load" tab, and find the "cpf" directory (under this one) to load the two pipelines. 

## REST configuration
So much configuration!
1. The CPF action is run as libary extensions for the REST server you installed on port 7001 above.  You need to intstall them with some http client.  With curl, try:

curl -X PUT --user admin:admin --anyauth -Hcontent-type:application/xquery --data-binary @'cpf/actions/jena-service-action.xqy' http://localhost:7001/v1/ext/actions/jena-service-action.xqy

If you need to edit these actions, simply re PUT them to the server to deploy and they will take effect on new CPF invocations.

## Usage

To run the server, in a screen session run

java -jar target/xxxx.jar

where xxxx. is the standalone version of the project that includes all dependent Java libraries.

## Build

If you need to build the server, you will need a JDK and Leiningen, the clojure build tool.  There should be a runnable jar however in the target/ directory for your use.

If you have lein:

lein run

will run the server.  

lein uberjar

will build the runnable standalone jar above.


## License

Copyright © 2014 MarkLogic Corporation

Distributed under the Eclipse Public License, the same as Clojure.
