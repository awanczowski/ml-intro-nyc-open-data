(:
: Copyright 2013 Andrew Wanczowski
: 
: Licensed under the Apache License, Version 2.0 (the "License");
: you may not use this file except in compliance with the License.
: You may obtain a copy of the License at
:
:   http://www.apache.org/licenses/LICENSE-2.0

: Unless required by applicable law or agreed to in writing, software
: distributed under the License is distributed on an "AS IS" BASIS,
: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
: See the License for the specific language governing permissions and
: limitations under the License.
:)

xquery version "1.0-ml";

import module namespace json = "http://marklogic.com/json"  at "/lib/xquery/json.xqy";
import module namespace model = "http://nycopendata.socrata.com/model/search" at "/model/search-model.xqy";

declare namespace controller = "http://nycopendata.socrata.com/controller/search";

(:~
: Create a json string based on a users search criteria
: @return a json string of the search
:)
declare function controller:find-json() as xs:string {
    let $node := model:find()
    let $preped-for-json := xdmp:xslt-invoke("/lib/xslt/prepareForJSON.xsl", $node)
    return 
    (
        json:serialize($preped-for-json),
        xdmp:set-response-content-type("application/json")
    )
};

(:~
: Create a XML node based on a users search criteria
: @return a find element of the search
:)
declare function controller:find-xml() as element(find) {
    model:find(),
    xdmp:set-response-content-type("text/xml")
};

(: Implicet call to find function :)
if(xdmp:get-request-field("format") eq "xml")
then controller:find-xml()
else controller:find-json()