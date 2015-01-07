An Introduction to Search Visualization Using NYC Open Data
===========================================================

Leveraging the power of MarkLogic's search API, one is able to build a fully functional, 
rapid prototype of a data visualization application. Learn how to utilize Marklogic search 
to drive data visualization widgets and map geospatial coordinates via template-based search results. 

It's simple to get started. All you need is some background in W3 standards (HTML, CSS, JavaScript) 
and MarkLogic. The data for this particular application was obtained for free from NYC Open Data (Socarta).

Due to restrictions this project is distributed with KendoUI Web under the GPL license. The Kendo UI DataViz 
JavaScript Library is required for frequency graphing. To download a trial or purchase the module please visit
http://www.kendoui.com/. Once completed place the necessary files under /resources/js and /resources/css/themes/kendo.

Sample data for this project is located in /data/content.zip. To help you get started a configuration file for all
database and app server settings has been included in the project under /config/NYCOpenData-311-config.xml.

If you would like to setup everything manually please follow the steps below:

	1. Log Into the MarkLogic admin UI(http://localhost:8001) and click the Database link in the left hand column.   

	2. Click the create link in the upper menu and specify the following configurations  
	    2a. Database Name: NYCOpenData-311  
	    2b. uri lexicon: true  
	    2c. click ok  

	3. Create a forest to store the NYC Open Data.   
	    3a. Click the link in the forest message "This database has no forests, select Database->Forests to attach a forest.".  
	    3b. Click Create Forest  
	    3c. Configure your forest and give it a name Ex. NYCOpenData-311-Forest  
	    3d. Click the database link in the side navigation once again.  
	    3e. Click forests, check the newly created forest name and click ok to mount the forest.  

	4. Configure the following element range indexes  
	    4a. scalar type: string  
	        localname : agency  
	        collation: codepoint  
	    4b. scalar type: string  
	        localname: complaint_type  
	        collation: codepoint  
	    4c. scalar type: dateTime  
	        localname: created_date  
        
	5. Configure the following attribute range indexes  
	    5a. scalar type: int  
	        parent localname: created_date  
	        localname: year  
	    5b. scalar type: int  
	        parent localname: created_date  
	        localname: month  
	    5c. scalar type: int  
	        parent localname: created_date  
	        localname: day  
	
	8. Create an HTTP app server pointing to the src directory located in the project.  
	    8a. Click Groups -> Default -> App Servers  
	    8b. Click the Create HTTP tab  
	    8c. Give your app server a name ex: NYCOpenData-311-Web  
	    8d. Specify "root" this is the full path to your /src directory of the project.  
	    8e. Specify a port ex:8010  
	    8f. Select the newly created database.  
	    
	9. Unzip the content example included in the project under /data/content.zip  
	10. Open an new tab and start up information studio (localhost:8000/appservices/)   
	    10a. Click new flow  
	    10b. Edit and name your new flow  
	    10c. Click configure and specify the path the the newly unzipped folder.  
	    10d. Click document settings and specify the follwoing uri setting then click done  
	        {$path strip-prefix="<the path to your folder>"}/{$filename}{$dot-ext}        
	    10e. Click start loading  

	11. Go to http://<your appserver url>/views/search.html and conduct a search.  