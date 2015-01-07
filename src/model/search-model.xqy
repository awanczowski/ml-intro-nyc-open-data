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

module namespace model = "http://nycopendata.socrata.com/model/search";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";

declare default collation "http://marklogic.com/collation/codepoint";

declare option xdmp:mapping "false";

declare variable $DEFAULT-QUERY-OPTIONS := 
   <options xmlns="http://marklogic.com/appservices/search">
       <return-results>true</return-results>
       <return-facets>true</return-facets>
       <return-query>true</return-query>
       <constraint name="agency">
        <range type="xs:string" collation="http://marklogic.com/collation/codepoint">
          <element ns="" name="agency"/>
          <facet-option>frequency-order</facet-option>
          <facet-option>descending</facet-option>
          <facet-option>limit=5</facet-option>
        </range>
       </constraint>
       <constraint name="complaint">
        <range type="xs:string" collation="http://marklogic.com/collation/codepoint">
          <element ns="" name="complaint_type"/>
          <facet-option>frequency-order</facet-option>
          <facet-option>descending</facet-option>
          <facet-option>limit=5</facet-option>
        </range>
       </constraint>
       <constraint name="year">
        <range type="xs:int">
          <element ns="" name="created_date"/>
          <attribute ns="" name="year" />
          <facet-option>frequency-order</facet-option>
          <facet-option>descending</facet-option>
          <facet-option>limit=5</facet-option>
        </range>
       </constraint>
       <constraint name="month">
        <range type="xs:int">
          <element ns="" name="created_date"/>
          <attribute ns="" name="month" />
        </range>
       </constraint>
   </options>;

(:~
: Create a find element that will have all the search information, 
: results, facets and graph axises.
: @return find node produced by search:search and other functions
:)
declare function model:find() as element(find) {
    let $results as element(search:response) := model:search()
   
    let $qtext   as xs:string? := $results/search:qtext/text()
    
    let $pLength as xs:integer := fn:data($results/@page-length)
    let $total   as xs:integer := fn:data($results/@total)
    let $start   as xs:integer := fn:data($results/@start)
    let $end     as xs:integer := $start + $pLength - 1
     
    let $prev as xs:integer? := 
         if($start >= $pLength) 
         then $start - $pLength
         else ()
     
    let $next as xs:integer? := 
         if( $end >= $total) 
         then ()
         else $end
    
    return
        <find>
             <total>{fn:data($results/@total)}</total>
             <query>{$qtext}</query>
             <fromResult>{$start}</fromResult>
             <toResult>{$end}</toResult>
             <previous>{$prev}</previous>
             <next>{$next}</next>
             <results>{
                for $result in $results/search:result
                return
                    <result>
                    {(
                        <position>{fn:data($result/@index)}</position>,
                        fn:doc($result/@uri)/row/node()
                    )}</result>
             }</results>
             <facets>
                <agencies>{
                    for $facet in $results/search:facet[@name = "agency"]/search:facet-value
                    return model:build-facet($facet,$qtext)
                }</agencies>
                <complaints>{
                    for $facet in $results/search:facet[@name = "complaint"]/search:facet-value
                    return model:build-facet($facet,$qtext)
                }</complaints>
                <years>{
                    for $facet in $results/search:facet[@name = "year"]/search:facet-value
                    return model:build-facet($facet,$qtext)
                }</years>
             </facets>
             { model:get-graph($results/search:query/node()) }
      </find>
};

(:~
: Perform a search:search based on the users request to the server.
: @return search:response node produced by search:search
:)
declare function model:search() as element(search:response) {
    let $query   as xs:string  := xdmp:get-request-field("query", "")
    let $start   as xs:integer := xdmp:get-request-field("start", "1") cast as xs:integer
    let $pLength as xs:integer := xdmp:get-request-field("page-length", "10") cast as xs:integer
    return
       search:search($query, $DEFAULT-QUERY-OPTIONS, $start, $pLength)
};

(:~
: Create all the axises for a given query to be graphed.
: @param $query the cts:query that will bind the search
: @return a axises element
:)
declare function model:get-graph($query as element()?) as element(graph) {
  let $cos as element(cts:co-occurrence)* := 
        cts:element-attribute-value-co-occurrences(
          xs:QName("created_date"),
          xs:QName("year"),
          xs:QName("created_date"),
          xs:QName("month"), 
          (),
          cts:query($query)
        )

  let $firstYear  as xs:integer? := $cos[1]/cts:value[1]/text()
  let $firstMonth as xs:integer? := $cos[1]/cts:value[2]/text()
  let $lastYear   as xs:integer? := $cos[fn:last()]/cts:value[1]/text()
  let $lastMonth  as xs:integer? := $cos[fn:last()]/cts:value[2]/text()
  
  let $axises as element(axis)*:=
      for $year in $cos[1]/cts:value[1]/text() to $cos[fn:last()]/cts:value[1]/text()
      return 
         <axis>
           <value>{$year}</value>
           <months>{
               (: Use some conditional coding to fill in the months that we have no records for so you can plot a full axis :)
               if ($year eq $firstYear) 
               then 
                    for $month in $firstMonth to 12  
                    return model:build-month-point($year, $month, $cos)
               else if($year eq $lastYear)
               then 
                    for $month in 1 to $lastMonth  
                    return model:build-month-point($year, $month, $cos)
               else 
                    for $month in 1 to 12 
                    return model:build-month-point($year, $month, $cos)
           }</months>
         </axis>
  
  return  
      <graph>
         <numberOfAxises>{fn:count($axises)}</numberOfAxises>
         <axises>{$axises}</axises>
      </graph>
};

(:~
: Create a point to be graphed. 
: @param $year  the year to constrain the search
: @param $month the month to constrain the search
: @param $cos the co-occurrences to fetch the frequency
: @return a point element
:)
declare function model:build-month-point($year as xs:integer, $month as xs:integer, $cos as element(cts:co-occurrence)*) as element(point) {
  (: Fetch the matching co-occurrence from the set :)
  let $selectedCo as element(cts:co-occurrence)? := $cos[./cts:value[1] eq $year and ./cts:value[2] eq $month]
  
  (: If there is a co-occurence calculate the frequency :)
  let $value as xs:integer :=  
    if($selectedCo)
    then cts:frequency($selectedCo)
    else 0
  
  return   
      <point>
        <month>{$month}</month>
        <year>{$year}</year>
        <count>{$value}</count>
      </point>
};

(:~
: Create an element for a facet passed in with a built out query  
: to constrain on as well as a boolean of it is previously selected.
: @param $facet the value of a search:facet-value created by search:search.
: @param $qtext the query the user has made.
: @return a facet element
:)
declare function model:build-facet($facet as element(search:facet-value), $qtext as xs:string?) as element(facet) { 
   let $facetQuery as xs:string := fn:concat(fn:data($facet/parent::search:facet/@name), ':"' , $facet/text(),'"')  
   let $containsFacet as xs:boolean := fn:contains($qtext,$facetQuery)
   
   let $query as xs:string := 
       if($containsFacet)
       then search:remove-constraint($qtext,$facetQuery, $DEFAULT-QUERY-OPTIONS)
       else 
           if (fn:string-length(fn:normalize-space($qtext)) > 0) 
           then fn:string-join(($qtext,$facetQuery) , " AND ")
           else $facetQuery
   return    
       <facet>
            <value>{$facet/text()}</value>
            <count>{fn:data($facet/@count)}</count>
            <query>{$query}</query>
            <selected>{$containsFacet}</selected>
       </facet>
};