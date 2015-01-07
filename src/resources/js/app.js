/************************************************************************
Copyright 2013 Andrew Wanczowski

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
************************************************************************/

jQuery(document).ready(function () {
    var browserQueryString = window.location.search;
    
    if (browserQueryString) {
        jQuery("#loading").toggle();
        jQuery.getJSON(
        "/controller/search-controller.xqy" + browserQueryString,
        function (data) {
            renderSearch(data);
            jQuery("#loading").toggle();
        });
    }
});

function renderSearch(search) {
    // Render basic search features
    renderResults(search.results);
    renderPagination(search);
    renderFacets(search.facets);
    
    jQuery("#totals .huge").html(search.total);
    jQuery("#quicksearch input[name=query]").attr('value', search.query);
    
    // Render search visualization features
    renderGraph(search.graph);
    renderMap(search.results)
    
    jQuery("#intro").hide();
    jQuery("#searchWrapper").css("visibility", "visible");
}

function renderResults(results) {
    // Result Template
    var template = kendo.template(jQuery("#resultTemplate").html());
    
    // Clear out the results area prior to appending each result
    var resultsItems = jQuery("#resultItems");
    resultsItems.empty();
    
    // Itterate through results and add each to the search area.
    jQuery.each(results, function (index, result) {
        // Create the result node
        resultsItems.append(template({
            position: result.position || "",
            complaint_type: result.complaint_type || "",
            descriptor: result.descriptor || "",
            incident_address: result.incident_address || "",
            city: result.city || "",
            incident_zip: result.incident_zip || "",
            status: result.status || "",
            created_date: result.created_date || ""
        }));
    });
}

function renderPagination(search) {
    // Create the search info node
    var aboutTemplate = kendo.template(jQuery("#paginationTemplate").html());
    jQuery("#pagination").html(aboutTemplate({
        fromResult: search.fromResult || "",
        toResult: search.toResult || "",
        total: search.total || ""
    }));
    
    // Create the search prev/next links
    var linkTemplate = kendo.template(jQuery("#prevNextLinkTemplate").html());
    jQuery("#prevNextLink").empty();
    if (search.previous) {
        jQuery("#prevNext").append(linkTemplate({
            query: encodeURIComponent(search.query),
            start: search.previous,
            text: "Previous"
        }));
    }
    
    if (search.next) {
        jQuery("#prevNext").append(linkTemplate({
            query: encodeURIComponent(search.query),
            start: search.next,
            text: "Next"
        }));
    }
}

function renderFacets(facets) {
    // Facet Template
    var template = kendo.template(jQuery("#facet").html());
    
    // append years
    jQuery("#years").empty();
    jQuery.each(facets.years, function (index, facet) {
        jQuery("#years").append(template({
            query: encodeURIComponent(facet.query),
            value: facet.value,
            count: facet.count,
            cssClass: facet.selected ? "selected": "unselected",
            remove: facet.selected == "true" ? "[X]": ""
        }))
    });
    
    // Make the years strech across the top of UI.
    jQuery("#years li a").css("width", (100 / facets.years.length) - 2 + "%");
    
    // append agency
    jQuery("#agency .facetItems").empty();
    jQuery.each(facets.agencies, function (index, facet) {
        jQuery("#agency .facetItems").append(template({
            query: encodeURIComponent(facet.query),
            value: facet.value,
            count: facet.count,
            cssClass: facet.selected ? "selected": "unselected",
            remove: facet.selected == "true" ? "[X]": ""
        }))
    });
    
    // append complaintType
    jQuery("#cType .facetItems").empty();
    jQuery.each(facets.complaints, function (index, facet) {
        jQuery("#cType .facetItems").append(template({
            query: encodeURIComponent(facet.query),
            value: facet.value,
            count: facet.count,
            cssClass: facet.selected ? "selected": "unselected",
            remove: facet.selected == "true" ? "[X]": ""
        }))
    });
}

function renderGraph(graph) {
    // Instantiate an array to place all the axises into.
    var graphSeries =[];

    // Create each of the graph axises to be plotted
    jQuery.each(graph.axises, function (pos, axis) {
        var sMap = {};
        sMap["name"] = axis.value;
        
        var data =[];
        jQuery.each(axis.months, function (pos, month) {
            data.push(month.count);
        });
        
        sMap["data"] = data;
        graphSeries.push(sMap);
    });
    
    // Create the Kendo Graph
    jQuery("#graph").kendoChart({
        theme: "blueopal",
        legend: {
            position: "bottom"
        },
        seriesDefaults: {
            type: "line"
        },
        series: graphSeries,
        categoryAxis: {
            categories:[ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        },
        tooltip: {
            visible: true,
            template: "${value}"
        }
    });
}

function renderMap(results) {
    var map, bounds;
    
    // Initalize the map with New York centered.
    var mapOptions = {
        zoom: 10,
        center: new google.maps.LatLng(40.748297, - 73.993778),
        mapTypeId: google.maps.MapTypeId.TERRAIN
    };
    
    // Fetch the DOM element for the map create the map and set it to the global variable
    map = new google.maps.Map(jQuery("#mapCanvas")[0], mapOptions);
    
    // Create the Bounds for the mapp and set it to the global variable
    bounds = new google.maps.LatLngBounds();
    
    // Itterate through the results and map the points
    jQuery.each(results, function (index, result) {
        
        if (result.latitude != null && result.longitude != null) {
            // Create a new Google Maps Lat Lang
            var latLng = new google.maps.LatLng(result.latitude, result.longitude)
            
            // Create a Google Maps Marker
            var marker = new google.maps.Marker({
                position: latLng,
                map: map
            });
            
            // Extend the bounds of the map.
            bounds.extend(latLng);
        } else {
            // Log if you do not have enough info to plot the point
            console.log("Unable to fetch coordinates from placemark");
        }
    });
    
    // Center the map around the plotted points
    map.fitBounds(bounds);
}