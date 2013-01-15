class DashboardView extends Backbone.View
  initialize: ->
    $("html").append "
      <link href='js-libraries/Leaflet/leaflet.css' type='text/css' rel='stylesheet' />
      <script type='text/javascript' src='js-libraries/Leaflet/leaflet.js'></script>
      <script type='text/javascript'>
      function toggle(div1) {
          var el = document.getElementById(div1);
          if (el.style.display != '')
          {
              el.style.display = '';
          } else {
              el.style.display = 'none';
          }
      }
      </script>
      <style>
        .dissaggregatedResults{
          display: none;
        }
      </style>
    "

  el: '#content'

  # events:
    # "change #reportOptions": "update"
    # "change #summaryField": "summarize"
    # "click #toggleDisaggregation": "toggleDisaggregation"

  update: =>
    reportOptions =
      startDate: $('#start').val()
      endDate: $('#end').val()
      reportType: $('#report-type :selected').text()

    _.each @locationTypes, (location) ->
      reportOptions[location] = $("##{location} :selected").text()

    url = "reports/" + _.map(reportOptions, (value, key) ->
      "#{key}/#{escape(value)}"
    ).join("/")

    Coconut.router.navigate(url,true)

  render: (options) =>
    @reportType = options.reportType || "results"
    @startDate = options.startDate || moment(new Date).subtract('days',30).format("YYYY-MM-DD")
    @endDate = options.endDate || moment(new Date).format("YYYY-MM-DD")

    # Coconut.questions.fetch
    #       success: =>

    @$el.html "
    <style>
      table.results th.header, table.results td{
        font-size:150%;
      }

    </style>

    <table id='reportOptions'></table>
    "

        # $("#reportOptions").append @formFilterTemplate(
        #           id: "question"
        #           label: "Question"
        #           form: "
        #               <select id='selected-question'>
        #                 #{
        #                   Coconut.questions.map( (question) ->
        #                     "<option>#{question.label()}</option>"
        #                   ).join("")
        #                 }
        #               </select>
        #             "
        #         )
        # 
        #       $("#reportOptions").append @formFilterTemplate(
        #         id: "start"
        #         label: "Start Date"
        #         form: "<input id='start' type='date' value='#{@startDate}'/>"
        #       )
        # 
        #       $("#reportOptions").append @formFilterTemplate(
        #         id: "end"
        #         label: "End Date"
        #         form: "<input id='end' type='date' value='#{@endDate}'/>"
        #       )

     
#    selectedLocations = {}
#    _.each @locationTypes, (locationType) ->
#      selectedLocations[locationType] = this[locationType]
#
#    _.each @locationTypes, (locationType,index) =>
#
#      $("#reportOptions").append @formFilterTemplate(
#        id: locationType
#        label: locationType.capitalize()
#        form: "
#          <select id='#{locationType}'>
#            #{
#              locationSelectedOneLevelHigher = selectedLocations[@locationTypes[index-1]]
#              _.map( ["ALL"].concat(@hierarchyOptions(locationType,locationSelectedOneLevelHigher)), (hierarchyOption) ->
#                "<option #{"selected='true'" if hierarchyOption is selectedLocations[locationType]}>#{hierarchyOption}</option>"
#              ).join("")
#            }
#          </select>
#        "
#      )


      # $("#reportOptions").append @formFilterTemplate(
      #         id: "report-type"
      #         label: "Report Type"
      #         form: "
      #         <select id='report-type'>
      #           #{
      #             _.map(["spreadsheet","results","summarytables"], (type) =>
      #               "<option #{"selected='true'" if type is @reportType}>#{type}</option>"
      #             ).join("")
      #           }
      #         </select>
      #         "
      #       )
      
    this[@reportType]()

    $('div[data-role=fieldcontain]').fieldcontain()
    $('select').selectmenu()
    $('input[type=date]').datebox {mode: "calbox"}


  hierarchyOptions: (locationType, location) ->
    if locationType is "region"
      return _.keys WardHierarchy.hierarchy
    _.chain(WardHierarchy.hierarchy)
      .map (value,key) ->
        if locationType is "district" and location is key
          return _.keys value
        _.map value, (value,key) ->
          if locationType is "constituan" and location is key
            return _.keys value
          _.map value, (value,key) ->
            if locationType is "shehia" and location is key
              return value
      .flatten()
      .compact()
      .value()

  mostSpecificLocationSelected: ->
    mostSpecificLocationType = "region"
    mostSpecificLocationValue = "ALL"
    _.each @locationTypes, (locationType) ->
      unless this[locationType] is "ALL"
        mostSpecificLocationType = locationType
        mostSpecificLocationValue = this[locationType]
    return {
      type: mostSpecificLocationType
      name: mostSpecificLocationValue
    }

  formFilterTemplate: (options) ->
    "
        <tr>
          <td>
            <label style='display:inline' for='#{options.id}'>#{options.label}</label> 
          </td>
          <td style='width:150%'>
            #{options.form}
            </select>
          </td>
        </tr>
    "

  viewQuery: (options) ->

    results = new DashboardCollection()
    results.fetch
      question: $('#selected-question').val()
      isComplete: true
      include_docs: true
      success: ->
        results.fields = {}
        results.each (result) ->
          _.each _.keys(result.attributes), (key) ->
            results.fields[key] = true unless _.contains ["_id","_rev","question"], key
        results.fields = _.keys(results.fields)
        options.success(results)


  results: ->
    @$el.append  "
      <table id='results' class='tablesorter'>
        <thead>
        </thead>
        <tbody>
        </tbody>
      </table>
    "

    @viewQuery
      success: (results) =>
	   
        tableData = results.map (result) ->
          _.map results.fields, (field) ->
            result.get field

        # $("table#results thead tr").append "
        #           #{ _.map(results.fields, (field) ->
        #             "<th>#{field}</th>"
        #           ).join("")
        #           }
        #         "
        # console.log("results: " + JSON.stringify(results))
        
        startDate = null
        endDate = null
        results.each (row) ->
            timestamp = row.get('timestamp')
            # console.log("timestamp: " + $.format.date(new Date(timestamp), "dd/MM/yyyy") )
            if startDate != null and timestamp < startDate
                startDate = timestamp
            else if endDate != null and timestamp > endDate
                endDate = timestamp
            
            if startDate == null	
                startDate = timestamp
            if endDate == null	
                endDate = timestamp

        # Setting up the header row of visit dates
        #http://stackoverflow.com/questions/7114152/given-a-start-and-end-date-create-an-array-of-the-dates-between-the-two
        s = new Date(startDate)
        e = new Date(endDate)
        
        visitDates = []
        visitDates.push(new Date(startDate))
        # console.log("visitDates: " + visitDates )
        
        while(s < e)
            visitDates.push(s)
            s = new Date s.setDate(s.getDate() + 1)
        
        headerVisitDates = ($.format.date(visitDate, "dd/MM/yyyy") for visitDate in visitDates)
        # console.log("headerVisitDates: " + headerVisitDates)
        headerVisitDatesTH = ("<th class=\"header\">" + headerVisitDate + "</th>" for headerVisitDate in headerVisitDates)
        # console.log("headerVisitDatesTH: " + headerVisitDatesTH)
    
        $("table#results thead").append "<tr><th class=\"header\">Enumerator</th>" + headerVisitDatesTH + "</tr>"
        

        # Looping through the records and building the table. 
        # We will stuff the html into sBuf and then append it to the results table.
        currentEnumerator = null;
        enumeratorVisitsPerDay = {}
        enumeratorTDs = ""
        hiddenInfoPerDay = {}
        results.each (row) ->
            #console.log("row: " + JSON.stringify(row))
            timestamp = row.get('timestamp')
            timestampDateFmt = $.format.date(new Date(timestamp), "dd/MM/yyyy");
            id = row.get('_id')
            assessmentId = row.get('assessmentId')
            if currentEnumerator != row.get('enumerator')
                 if currentEnumerator == null
                     # console.log("currentEnumerator is null: " + currentEnumerator)
                     currentEnumerator = row.get('enumerator')
                     #enumeratorVisitsPerDay = (enumeratorVisitsPerDay[headerVisitDate] for headerVisitDate in headerVisitDates)
                     enumeratorVisitsPerDay[timestampDateFmt] = 1
                     hiddenInfoPerDay[timestampDateFmt] = timestampDateFmt + " : " + assessmentId + "<br/>\n"
                     enumeratorTDs = "<tr><td>" + currentEnumerator + "</td>"
                 else
                     # console.log("enumeratorVisitsPerDay : " + JSON.stringify(enumeratorVisitsPerDay))
                     for headerVisitDate in headerVisitDates
                         if enumeratorVisitsPerDay[headerVisitDate] != undefined
                             enumeratorTDs = enumeratorTDs + "<td id=\"" + currentEnumerator + headerVisitDate + "\" onClick=\"toggle('hidden_" + currentEnumerator + 
                             headerVisitDate + "')\">" + enumeratorVisitsPerDay[headerVisitDate] + 
                             "<span id=\"hidden_" + currentEnumerator + headerVisitDate + "\" style=\"display: none;\"><br/>" + hiddenInfoPerDay[headerVisitDate] + "</span></td>" 
                         else 
                             enumeratorTDs = enumeratorTDs + "<td id=\"" + currentEnumerator + headerVisitDate + "\">0</td>"  
                     # console.log("enumeratorTDs : " + enumeratorTDs)
                     $("table#results tbody").append enumeratorTDs
                     enumeratorTDs = ""
                     enumeratorVisitsPerDay = {}
                     hiddenInfoPerDay = {}
                     # console.log("currentEnumerator is : " + currentEnumerator)
                     currentEnumerator = row.get('enumerator')
                     enumeratorTDs = "<tr><td>" + currentEnumerator + "</td>"
                     hiddenInfoPerDay[timestampDateFmt] = timestampDateFmt + " : " + assessmentId + "<br/>\n"
                     if enumeratorVisitsPerDay[timestampDateFmt] == undefined
                        enumeratorVisitsPerDay[timestampDateFmt] = 1
                     else
                        # console.log("Checking enumeratorVisitsPerDay[timestampDateFmt]: " + enumeratorVisitsPerDay[timestampDateFmt])
                        enumeratorVisitsPerDay[timestampDateFmt]  = enumeratorVisitsPerDay[timestampDateFmt] + 1
                 # $("table#results tbody").append "<tr><td>#{currentEnumerator}</td><td>#{timestamp}</td>"
            else
                 if hiddenInfoPerDay[timestampDateFmt]  == undefined
                    hiddenInfoPerDay[timestampDateFmt] = timestampDateFmt + " : " + assessmentId + "<br/>\n"
                 else 
                    hiddenInfoPerDay[timestampDateFmt] = hiddenInfoPerDay[timestampDateFmt] + timestampDateFmt + " : " + assessmentId + "<br/>\n"
                 if enumeratorVisitsPerDay[timestampDateFmt] == undefined
                     enumeratorVisitsPerDay[timestampDateFmt] = 1
                  else
                     enumeratorVisitsPerDay[timestampDateFmt]  = enumeratorVisitsPerDay[timestampDateFmt] + 1
        # console.log("last enumeratorVisitsPerDay : " + JSON.stringify(enumeratorVisitsPerDay))
        for headerVisitDate in headerVisitDates
             if enumeratorVisitsPerDay[headerVisitDate] != undefined
                 enumeratorTDs = enumeratorTDs + "<td id=\"" + currentEnumerator + headerVisitDate + "\" onClick=\"toggle('hidden_" + currentEnumerator + 
                  headerVisitDate + "')\">" + enumeratorVisitsPerDay[headerVisitDate] + 
                 "<span id=\"hidden_" + currentEnumerator + headerVisitDate + "\" style=\"display: none;\"><br/>" + hiddenInfoPerDay[headerVisitDate] + "</span></td>" 
             else 
                 enumeratorTDs = enumeratorTDs + "<td id=\"" + currentEnumerator + headerVisitDate + "\">0</td>"  
        # console.log("enumeratorTDs : " + enumeratorTDs)
        $("table#results tbody").append enumeratorTDs
        # $("table#results tbody").append "<tr><td colspan='8'>&nbsp;</td></tr><tr><td colspan='8'>Debugging - raw data</td></tr>"
        #         $("table#results tbody").append _.map(tableData, (row) ->  "
        #           <tr>
        #           <td>#{row[3]}</td>
        #              #{_.map(row, (element,index) -> "
        #                           <td>#{element}</td>
        #                         ").join("")
        #                         }
        #           
        #           </tr>
        #         ").join("")

        _.each $('table tr'), (row, index) ->
          $(row).addClass("odd") if index%2 is 1
