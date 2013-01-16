// Generated by CoffeeScript 1.4.0
var DashboardView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

DashboardView = (function(_super) {

  __extends(DashboardView, _super);

  function DashboardView() {
    this.render = __bind(this.render, this);

    this.update = __bind(this.update, this);

    this.updateDashboard = __bind(this.updateDashboard, this);
    return DashboardView.__super__.constructor.apply(this, arguments);
  }

  DashboardView.prototype.initialize = function() {
    return $("html").append("      <script type='text/javascript'>        function toggle(div) {            var el = document.getElementById(div);            if (el.style.display != '') {                el.style.display = '';            } else {                el.style.display = 'none';            }        }      </script>    ");
  };

  DashboardView.prototype.el = '#content';

  DashboardView.prototype.events = {
    "change #report-type": "update"
  };

  DashboardView.prototype.updateDashboard = function() {
    var reportTypeSelected;
    reportTypeSelected = $('#report-type').val();
    return alert("reportTypeSelected: " + reportTypeSelected);
  };

  DashboardView.prototype.update = function() {
    var reportOptions, url;
    reportOptions = {
      reportType: $('#report-type :selected').text()
    };
    this.reportType = reportOptions.reportType || "dashboard";
    url = "reports/" + _.map(reportOptions, function(value, key) {
      return "" + key + "/" + (escape(value));
    }).join("/");
    return Coconut.router.navigate(url, true);
  };

  DashboardView.prototype.render = function(options) {
    this.reportType = options.reportType || "results";
    this.reportOutput = "results";
    this.startDate = options.startDate || moment(new Date).subtract('days', 30).format("YYYY-MM-DD");
    this.endDate = options.endDate || moment(new Date).format("YYYY-MM-DD");
    this.$el.html("    <style>      table.results th.header, table.results td{        font-size:150%;      }    </style>    <table id='reportOptions'></table>    ");
    return this[this.reportOutput]();
  };

  DashboardView.prototype.viewQuery = function(options) {
    var results;
    results = new DashboardCollection();
    if (this.reportType === "enumerator") {
      results.comparator = function(result) {
        var date;
        date = new Date(result.get('timestamp'));
        return [new String(result.get('enumerator')), date.getTime()];
      };
    } else {
      results.comparator = function(result) {
        var date;
        date = new Date(result.get('timestamp'));
        return [new String(result.get('subtestData')[0].data.location[0]), date.getTime()];
      };
    }
    return results.fetch({
      question: $('#selected-question').val(),
      isComplete: true,
      include_docs: true,
      success: function() {
        results.fields = {};
        results.each(function(result) {
          return _.each(_.keys(result.attributes), function(key) {
            if (!_.contains(["_id", "_rev", "question"], key)) {
              return results.fields[key] = true;
            }
          });
        });
        results.fields = _.keys(results.fields);
        return options.success(results);
      }
    });
  };

  DashboardView.prototype.results = function() {
    var _this = this;
    this.$el.append("      <table id='results' class='tablesorter'>        <thead>        </thead>        <tbody>        </tbody>      </table>    ");
    return this.viewQuery({
      success: function(results) {
        var currentEnumerator, detailInfo, e, endDate, enumeratorTDs, enumeratorVisitsPerDay, headerVisitDate, headerVisitDates, headerVisitDatesTH, hiddenInfoPerDay, identifier, reportType, s, startDate, tableData, visitDate, visitDates, _i, _len;
        tableData = results.map(function(result) {
          return _.map(results.fields, function(field) {
            return result.get(field);
          });
        });
        startDate = null;
        endDate = null;
        results.each(function(row) {
          var timestamp;
          timestamp = row.get('timestamp');
          if (startDate !== null && timestamp < startDate) {
            startDate = timestamp;
          } else if (endDate !== null && timestamp > endDate) {
            endDate = timestamp;
          }
          if (startDate === null) {
            startDate = timestamp;
          }
          if (endDate === null) {
            return endDate = timestamp;
          }
        });
        s = new Date(startDate);
        e = new Date(endDate);
        visitDates = [];
        visitDates.push(new Date(startDate));
        while (s < e) {
          visitDates.push(s);
          s = new Date(s.setDate(s.getDate() + 1));
        }
        headerVisitDates = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = visitDates.length; _i < _len; _i++) {
            visitDate = visitDates[_i];
            _results.push($.format.date(visitDate, "dd/MM/yyyy"));
          }
          return _results;
        })();
        headerVisitDatesTH = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = headerVisitDates.length; _i < _len; _i++) {
            headerVisitDate = headerVisitDates[_i];
            _results.push("<th class=\"header\">" + headerVisitDate + "</th>");
          }
          return _results;
        })();
        $("table#results thead").append(("<tr><th class=\"header\">        <select data-role='selector' id='report-type'>                " + (_.map(["enumerator", "schoolname"], function(type) {
          return "<option " + (type === _this.reportType ? "selected='true'" : void 0) + ">" + type + "</option>";
        }).join("")) + "              </select>              </th>") + headerVisitDatesTH + "</tr>");
        reportType = _this.reportType;
        currentEnumerator = null;
        enumeratorVisitsPerDay = {};
        enumeratorTDs = "";
        detailInfo = "";
        hiddenInfoPerDay = {};
        results.each(function(row) {
          var assessmentId, id, identifier, reportSortField, timestamp, timestampDateFmt, _i, _len;
          timestamp = row.get('timestamp');
          timestampDateFmt = $.format.date(new Date(timestamp), "dd/MM/yyyy");
          id = row.get('_id');
          assessmentId = row.get('assessmentId');
          if (reportType === "enumerator") {
            reportSortField = row.get('enumerator');
          } else {
            reportSortField = row.get('subtestData')[0].data.location[0];
            detailInfo = "<br/>School: " + row.get('subtestData')[0].data.location[0] + "<br/>Code: " + row.get('subtestData')[0].data.location[1] + "<br/>Division: " + row.get('subtestData')[0].data.location[2] + "<br/>Region: " + row.get('subtestData')[0].data.location[3] + "<br/>Sample: " + row.get('subtestData')[0].data.location[4] + "<br/><br/>Records: ";
          }
          if (currentEnumerator !== reportSortField) {
            if (currentEnumerator === null) {
              currentEnumerator = reportSortField;
              enumeratorVisitsPerDay[timestampDateFmt] = 1;
              hiddenInfoPerDay[timestampDateFmt] = timestampDateFmt + " : " + assessmentId + "<br/>\n";
              return enumeratorTDs = "<tr><td>" + currentEnumerator + "</td>";
            } else {
              for (_i = 0, _len = headerVisitDates.length; _i < _len; _i++) {
                headerVisitDate = headerVisitDates[_i];
                identifier = currentEnumerator.replace(/\s/g, "") + headerVisitDate;
                if (enumeratorVisitsPerDay[headerVisitDate] !== void 0) {
                  enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\" onClick=\"toggle('hidden_" + identifier + "')\">" + enumeratorVisitsPerDay[headerVisitDate] + "<span id=\"hidden_" + identifier + "\" style=\"display: none;\">" + detailInfo + "<br/>" + hiddenInfoPerDay[headerVisitDate] + "</span></td>";
                } else {
                  enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\">0</td>";
                }
              }
              $("table#results tbody").append(enumeratorTDs);
              enumeratorTDs = "";
              enumeratorVisitsPerDay = {};
              hiddenInfoPerDay = {};
              currentEnumerator = reportSortField;
              enumeratorTDs = "<tr><td>" + currentEnumerator + "</td>";
              hiddenInfoPerDay[timestampDateFmt] = timestampDateFmt + " : " + assessmentId + "<br/>\n";
              if (enumeratorVisitsPerDay[timestampDateFmt] === void 0) {
                return enumeratorVisitsPerDay[timestampDateFmt] = 1;
              } else {
                return enumeratorVisitsPerDay[timestampDateFmt] = enumeratorVisitsPerDay[timestampDateFmt] + 1;
              }
            }
          } else {
            if (hiddenInfoPerDay[timestampDateFmt] === void 0) {
              hiddenInfoPerDay[timestampDateFmt] = timestampDateFmt + " : " + assessmentId + "<br/>\n";
            } else {
              hiddenInfoPerDay[timestampDateFmt] = hiddenInfoPerDay[timestampDateFmt] + timestampDateFmt + " : " + assessmentId + "<br/>\n";
            }
            if (enumeratorVisitsPerDay[timestampDateFmt] === void 0) {
              return enumeratorVisitsPerDay[timestampDateFmt] = 1;
            } else {
              return enumeratorVisitsPerDay[timestampDateFmt] = enumeratorVisitsPerDay[timestampDateFmt] + 1;
            }
          }
        });
        for (_i = 0, _len = headerVisitDates.length; _i < _len; _i++) {
          headerVisitDate = headerVisitDates[_i];
          identifier = currentEnumerator.replace(/\s/g, "") + headerVisitDate;
          if (enumeratorVisitsPerDay[headerVisitDate] !== void 0) {
            enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\" onClick=\"toggle('hidden_" + identifier + "')\">" + enumeratorVisitsPerDay[headerVisitDate] + "<span id=\"hidden_" + identifier + "\" style=\"display: none;\">" + detailInfo + "<br/>" + hiddenInfoPerDay[headerVisitDate] + "</span></td>";
          } else {
            enumeratorTDs = enumeratorTDs + "<td id=\"" + identifier + "\">0</td>";
          }
        }
        $("table#results tbody").append(enumeratorTDs);
        return _.each($('table tr'), function(row, index) {
          if (index % 2 === 1) {
            return $(row).addClass("odd");
          }
        });
      }
    });
  };

  return DashboardView;

})(Backbone.View);
