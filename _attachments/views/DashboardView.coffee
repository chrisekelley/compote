class DashboardView extends Backbone.View
  initialize: ->
    $("html").append "
      <script type='text/javascript'>
        function toggle(div) {
            var el = document.getElementById(div);
            if (el.style.display != '') {
                el.style.display = '';
            } else {
                el.style.display = 'none';
            }
        }
      </script>
    "

  el: '#content'

  events:
    "change #report-type": "update"
    # "change #reportOptions": "update"
    # "change #summaryField": "summarize"
    # "click #toggleDisaggregation": "toggleDisaggregation"

  updateDashboard: =>
    reportTypeSelected = $('#report-type').val()
    alert("reportTypeSelected: " + reportTypeSelected)

  update: =>
    # reportTypeSelected = $('#report-type').val()
    # alert("reportType: " + reportType)
    
    reportOptions =
      # startDate: $('#start').val()
      #       endDate: $('#end').val()
      reportType: $('#report-type :selected').text()

    # _.each @locationTypes, (location) ->
    #       reportOptions[location] = $("##{location} :selected").text()
     
    this.reportType = reportOptions.reportType || "dashboard"; 
    
    url = "reports/" + _.map(reportOptions, (value, key) ->
      "#{key}/#{escape(value)}"
    ).join("/")

    Coconut.router.navigate(url,true)

  render: (options) =>
    @reportType = options.reportType || "results"
    @reportOutput = "results"
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
      
    this[@reportOutput]()


  viewQuery: (options) ->
    results = new DashboardCollection()
    if this.reportType == "enumerator"
        results.comparator = (result) ->
            date = new Date(result.get('timestamp'))
            [new String(result.get('enumerator')),date.getTime()]
    else
        results.comparator = (result) ->
            date = new Date(result.get('timestamp'))
            [new String(result.get('subtestData')[0].data.location[0]),date.getTime()]
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
        # <select id='reportTypeDropdown'><option value='enumerator'>Enumerator</option><option value='schoolname'>School Name</option></select></th>" + headerVisitDatesTH + "</tr>
        $("table#results thead").append "<tr><th class=\"header\">
        <select data-role='selector' id='report-type'>
                #{
                  _.map(["enumerator","schoolname"], (type) =>
                    "<option #{"selected='true'" if type is @reportType}>#{type}</option>"
                  ).join("")
                }
              </select>
              </th>" + headerVisitDatesTH + "</tr>"

        # Looping through the records and building the table. 
        reportType = this.reportType
        currentEnumerator = null;
        enumeratorVisitsPerDay = {}
        enumeratorTDs = ""
        detailInfo = ""
        hiddenInfoPerDay = {}
        results.each (row) ->
            #console.log("row: " + JSON.stringify(row))
            timestamp = row.get('timestamp')
            timestampDateFmt = $.format.date(new Date(timestamp), "dd/MM/yyyy");
            id = row.get('_id')
            assessmentId = row.get('assessmentId') 
            if reportType == "enumerator"
                reportSortField = row.get('enumerator')
            else
                reportSortField = row.get('subtestData')[0].data.location[0]
                detailInfo = "<br/>School: " + row.get('subtestData')[0].data.location[0] + 
                "<br/>Code: " + row.get('subtestData')[0].data.location[1] + 
                "<br/>Division: " + row.get('subtestData')[0].data.location[2] + 
                "<br/>Region: " + row.get('subtestData')[0].data.location[3] + 
                "<br/>Sample: " + row.get('subtestData')[0].data.location[4] + 
                "<br/><br/>Records: "
            if currentEnumerator != reportSortField
                 if currentEnumerator == null
                     # console.log("currentEnumerator is null: " + currentEnumerator)
                     currentEnumerator = reportSortField
                     #enumeratorVisitsPerDay = (enumeratorVisitsPerDay[headerVisitDate] for headerVisitDate in headerVisitDates)
                     enumeratorVisitsPerDay[timestampDateFmt] = 1
                     hiddenInfoPerDay[timestampDateFmt] = timestampDateFmt + " : " + assessmentId + "<br/>\n"
                     enumeratorTDs = "<tr><td>" + currentEnumerator + "</td>"
                 else
                     # console.log("enumeratorVisitsPerDay : " + JSON.stringify(enumeratorVisitsPerDay))
                     for headerVisitDate in headerVisitDates
                         identifier = currentEnumerator.replace(/\s/g, "") + headerVisitDate
                         if enumeratorVisitsPerDay[headerVisitDate] != undefined
                             enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\" onClick=\"toggle('hidden_" + identifier + "')\">" + 
                             enumeratorVisitsPerDay[headerVisitDate] + 
                             "<span id=\"hidden_" + identifier + "\" style=\"display: none;\">" + detailInfo + "<br/>" + hiddenInfoPerDay[headerVisitDate] + "</span></td>" 
                         else 
                             enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\">0</td>"  
                     # console.log("enumeratorTDs : " + enumeratorTDs)
                     $("table#results tbody").append enumeratorTDs
                     enumeratorTDs = ""
                     enumeratorVisitsPerDay = {}
                     hiddenInfoPerDay = {}
                     # console.log("currentEnumerator is : " + currentEnumerator)
                     currentEnumerator = reportSortField
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
             identifier = currentEnumerator.replace(/\s/g, "") + headerVisitDate
             if enumeratorVisitsPerDay[headerVisitDate] != undefined
                 enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\" onClick=\"toggle('hidden_" + identifier + "')\">" + enumeratorVisitsPerDay[headerVisitDate] + 
                 "<span id=\"hidden_" + identifier + "\" style=\"display: none;\">" + detailInfo + "<br/>" + hiddenInfoPerDay[headerVisitDate] + "</span></td>" 
             else 
                 enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\">0</td>"  
        #console.log("enumeratorTDs : " + enumeratorTDs)
        $("table#results tbody").append enumeratorTDs

        _.each $('table tr'), (row, index) ->
          $(row).addClass("odd") if index%2 is 1

 
