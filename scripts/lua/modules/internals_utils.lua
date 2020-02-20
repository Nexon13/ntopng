--
-- (C) 2019-20 - ntop.org
--

local format_utils = require("format_utils")
local internals_utils = {}
local json = require "dkjson"
local dirs = ntop.getDirs()
local user_scripts = require "user_scripts"

-- ###########################################

internals_utils.periodic_scripts_durations = {
   -- Script -> max_duration sec
   ["stats_update.lua"]      =     5,
   ["ht_state_update.lua"]   =     5,
   ["minute.lua"]            =    60,
   ["5min.lua"]              =   300,
   ["hourly.lua"]            =  3600,
   ["daily.lua"]             = 86400,
   ["housekeeping.lua"]      =     3,
   ["discover.lua"]          =     5,
   ["timeseries.lua"]        =     5,
   ["second.lua"]            =     1,
}

-- ###########################################

local function printHashTablesDropdown(base_url, page_params)
   local hash_table = _GET["hash_table"]
   local hash_table_filter
   if not isEmptyString(hash_table) then
      hash_table_filter = '<span class="fas fa-filter"></span>'
   else
      hash_table_filter = ''
   end
   local hash_table_params = table.clone(page_params)
   hash_table_params["hash_table"] = nil

   print[[\
      <button class="btn btn-link dropdown-toggle" data-toggle="dropdown">]] print(i18n("internals.hash_table")) print[[]] print(hash_table_filter) print[[<span class="caret"></span></button>\
      <ul class="dropdown-menu scrollable-dropdown" role="menu" id="flow_dropdown">\]]

   print[[<li><a class="dropdown-item" href="]] print(getPageUrl(base_url, hash_table_params)) print[[">]] print(i18n("internals.all_hash_tables")) print[[</a></li>\]]

   for ht, stats in pairsByKeys(interface.getHashTablesStats(), asc) do
      print[[ <li]] if hash_table == ht then print(' class="active"') end print[[><a class="dropdown-item" href="]] hash_table_params["hash_table"] = ht; print(getPageUrl(base_url, hash_table_params)); print[[">]] print(i18n("hash_table."..ht)) print[[</a></li>\]]
   end
end

-- ###########################################

local function printHashTablesTable(base_url, ifid, ts_creation)
   local page_params = {hash_table = _GET["hash_table"], tab = _GET["tab"], iffilter = ifid}

   print[[
<div id="table-system-interfaces-stats"></div>
<script type='text/javascript'>

$("#table-system-interfaces-stats").datatable({
   title: "]] print(i18n("internals.hash_tables")) print[[",]]

   local preference = tablePreferences("rows_number",_GET["perPage"])
   if preference ~= "" then print ('perPage: '..preference.. ",\n") end

   print[[
   showPagination: true,
   buttons: [ ]]

   -- Ip version selector
   print[['<div class="btn-group float-right">]]
   printHashTablesDropdown(base_url, page_params)
   print[[</div>']]

   print[[ ],
   url: "]] print(getPageUrl(ntop.getHttpPrefix().."/lua/get_internals_hash_tables_stats.lua", page_params)) print[[",
   columns: [
     {
       field: "column_key",
       hidden: true,
     }, {
       field: "column_ifid",
       hidden: true,
     }, {
       title: "]] print(i18n("interface")) print[[",
       field: "column_name",
       hidden: ]] if ifid then print('true') else print('false') end print[[,
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.hash_table")) print[[",
       field: "column_hash_table_name",
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '10%',
       }
     }, {
       title: "]] print(i18n("chart")) print[[",
       field: "column_chart",
       hidden: ]] if not ifid or not ts_creation then print('true') else print('false') end print[[,
       sortable: false,
       css: {
	 textAlign: 'center',
	 width: '1%',
       }
     }, {
       title: "]] print(i18n("internals.state_active")) print[[",
       field: "column_active_entries",
       sortable: true,
       css: {
	 textAlign: 'right',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.state_idle")) print[[",
       field: "column_idle_entries",
       sortable: true,
       css: {
	 textAlign: 'right',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.hash_table_utilization")) print[[",
       field: "column_hash_table_utilization",
       sortable: true,
       css: {
	 textAlign: 'center',
	 width: '5%',
       }
     }
   ], tableCallback: function() {
      datatableInitRefreshRows($("#table-system-interfaces-stats"),
			       "column_key", 5000,
			       {"column_active_entries": addCommas,
				"column_idle_entries": addCommas});
   },
});
</script>
 ]]
end

-- ###########################################

local function printPeriodicactivityDropdown(base_url, page_params)
   local periodic_activity = _GET["periodic_script"]
   local periodic_activity_filter
   if not isEmptyString(periodic_activity) then
      periodic_activity_filter = '<span class="fas fa-filter"></span>'
   else
      periodic_activity_filter = ''
   end
   local periodic_activity_params = table.clone(page_params)
   periodic_activity_params["periodic_script"] = nil

   print[[\
      <button class="btn btn-link dropdown-toggle" data-toggle="dropdown">]] print(i18n("internals.periodic_activity")) print[[]] print(periodic_activity_filter) print[[<span class="caret"></span></button>\
      <ul class="dropdown-menu scrollable-dropdown" role="menu" id="flow_dropdown">\]]

   print[[<li><a class="dropdown-item" href="]] print(getPageUrl(base_url, periodic_activity_params)) print[[">]] print(i18n("internals.all_periodic_activities")) print[[</a></li>\]]

   for script, stats in pairsByKeys(interface.getPeriodicActivitiesStats(), asc) do
      print[[ <li><a class="dropdown-item ]] if periodic_activity == script then print('active') end print[[" href="]] periodic_activity_params["periodic_script"] = script; print(getPageUrl(base_url, periodic_activity_params)); print[[">]] print(script) print[[</a></li>\]]
   end
end

-- ###########################################

local function printPeriodicActivitiesTable(base_url, ifid, ts_creation)
   local page_params = {periodic_script = _GET["periodic_script"], tab = _GET["tab"], iffilter = ifid}

   print[[
<div id="table-internals-periodic-activities"></div>
<script type='text/javascript'>

$("#table-internals-periodic-activities").datatable({
   title: "]] print(i18n("internals.periodic_activities")) print[[",]]

   local preference = tablePreferences("rows_number",_GET["perPage"])
   if preference ~= "" then print ('perPage: '..preference.. ",\n") end

   print[[
   showPagination: true,
   buttons: [ ]]

   -- Ip version selector
   print[['<div class="btn-group float-right">]]
   printPeriodicactivityDropdown(base_url, page_params)
   print[[</div>']]

   print[[ ],
   url: "]] print(getPageUrl(ntop.getHttpPrefix().."/lua/get_internals_periodic_activities_stats.lua", page_params)) print[[",
   columns: [
     {
       field: "column_key",
       hidden: true,
     }, {
       field: "column_ifid",
       hidden: true,
     }, {
       title: "]] print(i18n("interface")) print[[",
       field: "column_name",
       hidden: ]] if ifid then print('true') else print('false') end print[[,
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.periodic_activity")) print[[",
       field: "column_periodic_activity_name",
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("chart")) print[[",
       field: "column_chart",
       hidden: ]] if not ifid or not ts_creation then print('true') else print('false') end print[[,
       sortable: false,
       css: {
	 textAlign: 'center',
	 width: '1%',
       }
     }, {
       title: "]] print(i18n("internals.time_usage")) print[[",
       field: "column_time_perc",
       sortable: true,
       css: {
	 textAlign: 'center',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("status")) print[[",
       field: "column_status",
       sortable: true,
       css: {
	 textAlign: 'center',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.last_start_time")) print[[",
       field: "column_last_start_time",
       sortable: true,
       css: {
	 textAlign: 'right',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.last_duration_ms")) print[[",
       field: "column_last_duration",
       sortable: true,
       css: {
	 textAlign: 'right',
	 width: '5%',
       }
     }
   ], tableCallback: function() {
      datatableInitRefreshRows($("#table-internals-periodic-activities"),
			       "column_key", 5000,
			       {
                  "column_last_duration": fmillis,
               });
   },
});
</script>
 ]]
end

-- ###########################################

local function printUserScriptsDropdown(base_url, page_params)
   local user_script_target = _GET["user_script_target"]
   local user_script_target_filter
   if not isEmptyString(user_script_target) then
      user_script_target_filter = '<span class="fas fa-filter"></span>'
   else
      user_script_target_filter = ''
   end
   local user_script_target_params = table.clone(page_params)
   user_script_target_params["user_script_target"] = nil

   print[[\
      <button class="btn btn-link dropdown-toggle" data-toggle="dropdown">]] print(i18n("internals.user_script_target")) print[[]] print(user_script_target_filter) print[[<span class="caret"></span></button>\
      <ul class="dropdown-menu" role="menu" id="flow_dropdown">\]]

   print[[<li><a class="dropdown-item" href="]] print(getPageUrl(base_url, user_script_target_params)) print[[">]] print(i18n("internals.all_user_script_targets")) print[[</a></li>\]]

   for _, subdir in pairsByKeys(user_scripts.listSubdirs(), asc) do
      print[[ <li]] if user_script_target == subdir["label"] then print(' class="active"') end print[[><a class="dropdown-item" href="]] user_script_target_params["user_script_target"] = subdir["label"]; print(getPageUrl(base_url, user_script_target_params)); print[[">]] print(subdir["label"]) print[[</a></li>\]]
   end
end

-- ###########################################

local function printUserScriptsTable(base_url, ifid, ts_creation)
   local page_params = {user_script_target = _GET["user_script_target"], tab = _GET["tab"], iffilter = ifid}

   print[[
<div id="table-internals-periodic-activities"></div>
<script type='text/javascript'>

$("#table-internals-periodic-activities").datatable({
   title: "]] print(i18n("internals.user_scripts")) print[[",]]

   local preference = tablePreferences("rows_number",_GET["perPage"])
   if preference ~= "" then print ('perPage: '..preference.. ",\n") end

   print[[
   showPagination: true,
   buttons: [ ]]

   -- Ip version selector
   print[['<div class="btn-group float-right">]]
   printUserScriptsDropdown(base_url, page_params)
   print[[</div>']]

   print[[ ],
   url: "]] print(getPageUrl(ntop.getHttpPrefix().."/lua/get_internals_user_scripts_stats.lua", page_params)) print[[",
   columns: [
     {
       field: "column_key",
       hidden: true,
     }, {
       field: "column_ifid",
       hidden: true,
     }, {
       title: "]] print(i18n("interface")) print[[",
       field: "column_name",
       hidden: ]] if ifid then print('true') else print('false') end print[[,
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.user_script")) print[[",
       field: "column_user_script_name",
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.user_script_target")) print[[",
       field: "column_user_script_target",
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("flow_callbacks.callback_function")) print[[",
       field: "column_hook",
       sortable: true,
       css: {
	 textAlign: 'left',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.last_num_calls")) print[[",
       field: "column_last_num_calls",
       sortable: true,
       css: {
	 textAlign: 'right',
	 width: '5%',
       }
     }, {
       title: "]] print(i18n("internals.last_duration_ms")) print[[",
       field: "column_last_duration",
       sortable: true,
       css: {
	 textAlign: 'right',
	 width: '5%',
       }
     }
   ], tableCallback: function() {
      datatableInitRefreshRows($("#table-internals-periodic-activities"),
			       "column_key", 5000,
			       {
                  "column_last_duration": fmillis,
                  "column_last_num_calls": fint,
               });
   },
});
</script>
 ]]
end

-- ###########################################

local function printTab(tab, content, sel_tab)
   if(tab == sel_tab) then print("\t<li class=active>") else print("\t<li>") end
   print("<a href=\""..ntop.getHttpPrefix().."/lua/"..page_name.."?page=alerts&tab="..tab)
   for param, value in pairs(page_params) do
      print("&"..param.."="..value)
   end
   print("\">"..content.."</a></li>\n")
end

-- ###########################################

function internals_utils.printInternals(ifid, print_hash_tables, print_periodic_activities, print_user_scripts)
   local tab = _GET["tab"]

   local ts_creation = areInternalTimeseriesEnabled(ifid or getSystemInterfaceId())

   print[[<ul class="nav nav-tabs" role="tablist">]]

   if print_hash_tables then
      if not tab then tab = "hash_tables" end
      print[[<li class="nav-item">
    <a class="nav-link ]] if tab == "hash_tables" then print[[active]] end print[[" href="?page=internals&tab=hash_tables]] print[[">]] print(i18n("internals.hash_tables")) print[[</a></li>]]
   end

   if print_periodic_activities then
      if not tab then tab = "periodic_activities" end
      print[[<li class="nav-item">
    <a class="nav-link ]] if tab == "periodic_activities" then print[[active]] end print[[" href="?page=internals&tab=periodic_activities"]] print[[">]] print(i18n("internals.periodic_activities")) print[[</a></li>]]
   end

   if print_user_scripts then
      if not tab then tab = "user_scripts" end
      print[[<li class="nav-item">
    <a class="nav-link ]] if tab == "user_scripts" then print[[active]] end print[[" href="?page=internals&tab=user_scripts"]] print[[">]] print(i18n("internals.user_scripts")) print[[</a></li>]]
   end

   print[[</ul>

<div class="tab-content clearfix">]]
   local base_url = "?page=internals"

   if tab == "hash_tables" and print_hash_tables then
      printHashTablesTable(base_url.."&tab=hash_tables", ifid, ts_creation)
   elseif tab == "periodic_activities" and print_periodic_activities then
      printPeriodicActivitiesTable(base_url.."&tab=periodic_activities", ifid, ts_creation)
   elseif tab == "user_scripts" and print_user_scripts then
      printUserScriptsTable(base_url.."&tab=user_scripts", ifid, ts_creation)
   end
   print[[</div>]]
end

-- ###########################################

function internals_utils.getHashTablesFillBar(first_fill_pct, second_fill_pct, third_fill_pct)
   local code = [[<div class="progress">]]

   if first_fill_pct > 0 then
      code = code..[[<div class="progress-bar" role="progressbar" title="]] ..i18n("if_stats_overview.active").. [[" style="width: ]]..first_fill_pct..[[%" aria-valuenow="]]..first_fill_pct..[[" aria-valuemin="0" aria-valuemax="100">]]..i18n("if_stats_overview.active")..[[</div>]]
   end

   if second_fill_pct > 0 then
      code = code..[[<div class="progress-bar bg-info" role="progressbar" title="]] ..i18n("flow_callbacks.idle").. [[" style="width: ]]..second_fill_pct..[[%" aria-valuenow="]]..second_fill_pct..[[" aria-valuemin="0" aria-valuemax="100">]]..i18n("flow_callbacks.idle")..[[</div>]]
   end

   if third_fill_pct > 0 then
      code = code..[[<div class="progress-bar bg-success" role="progressbar" title="]] ..i18n("available").. [[" style="width: ]]..third_fill_pct..[[%" aria-valuenow="]]..third_fill_pct..[[" aria-valuemin="0" aria-valuemax="100">]]..i18n("available")..[[</div>]]
   end

   code = code..[[</div>]]

   return code
end


-- ###########################################

function internals_utils.getPeriodicActivitiesFillBar(busy_pct, available_pct)
   local code = [[<div class="progress">]]

   if busy_pct > 0 then
      code = code..[[<div class="progress-bar" role="progressbar" title="]] ..i18n("busy").. [[" style="width: ]]..busy_pct..[[%" aria-valuenow="]]..busy_pct..[[" aria-valuemin="0" aria-valuemax="100">]]..i18n("busy")..[[</div>]]
   end

   if available_pct > 0 then
      code = code..[[<div class="progress-bar bg-success" role="progressbar" title="]] ..i18n("available").. [[" style="width: ]]..available_pct..[[%" aria-valuenow="]]..available_pct..[[" aria-valuemin="0" aria-valuemax="100">]]..i18n("available")..[[</div>]]
   end

   code = code..[[</div>]]

   return code
end

-- ###########################################

function internals_utils.printPeriodicActivityDetails(ifId, url)
   local periodic_script = _GET["periodic_script"]
   local schema = _GET["ts_schema"] or "custom:flow_script:stats"
   local selected_epoch = _GET["epoch"] or ""
   url = url..'&page=historical'

   local tags = {
      ifid = ifId,
      periodic_script = periodic_script,
   }

   local periodic_scripts_ts = {}

   for script, max_duration in pairsByKeys(internals_utils.periodic_scripts_durations) do
      periodic_scripts_ts[#periodic_scripts_ts + 1] = {
	 schema = "periodic_script:duration",
	 label = script,
	 extra_params = {periodic_script = script},
	 metrics_labels = {i18n("flow_callbacks.last_duration")},

	 -- Horizontal line with max duration
	 extra_series = {
	    {
	       label = i18n("internals.max_duration_ms"),
	       axis = 1,
	       type = "line",
	       color = "red",
	       value = max_duration * 1000,
	       class = "line-dashed",
	    },
	 }
      }
   end

   local timeseries = periodic_scripts_ts

   if tostring(ifId) ~= getSystemInterfaceId() then
      timeseries = table.merge(timeseries,
			       {
				  {
				     separator = 1,
				     label="ht_state_update.lua"
				  },
				  {
				     schema = "flow_script:lua_duration",
				     label = i18n("internals.flow_lua_duration"),
				     metrics_labels = {
					i18n("duration")
				     }
				  },
				  {
				     schema = "custom:flow_script:stats",
				     label = i18n("internals.flow_calls_stats"),
				     metrics_labels =
					{
					   i18n("internals.missed_idle"),
					   i18n("internals.missed_proto_detected"),
					   i18n("internals.missed_periodic_update"),
					   i18n("internals.pending_proto_detected"),
					   i18n("internals.pending_periodic_update"),
					   i18n("internals.successful_calls")
					},
				  },
      })
   end

   drawGraphs(ifId, schema, tags, _GET["zoom"], url, selected_epoch, { timeseries = timeseries })
   

end

-- ###########################################

return internals_utils
