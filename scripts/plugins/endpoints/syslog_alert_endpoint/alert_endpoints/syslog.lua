--
-- (C) 2018 - ntop.org
--

require "lua_utils"
local json = require "dkjson"
local alert_utils = require "alert_utils"
local alert_consts = require "alert_consts"
local format_utils = require "format_utils"

local syslog = {
   name = "Syslog",
   conf_max_num = 1, -- At most 1 endpoint
   conf_params = {
      { param_name = "syslog_alert_format" },
      { param_name = "syslog_protocol", optional = true },
      { param_name = "syslog_host", optional = true },
      { param_name = "syslog_port", optional = true },
   },
   conf_template = {
      plugin_key = "syslog_alert_endpoint",
      template_name = "syslog_endpoint.template"
   },
   recipient_params = {
   },
   recipient_template = {
      plugin_key = "syslog_alert_endpoint",
      template_name = "syslog_recipient.template"
   },
}

-- syslog.DEFAULT_SEVERITY = "info"
syslog.EXPORT_FREQUENCY = 1 -- 1 second, i.e., as soon as possible
syslog.prio = 300

-- ##############################################

function syslog.isAvailable()
   return(ntop.syslog ~= nil)
end

-- ##############################################

local function readSettings(recipient)
   local settings = {
      -- Endpoint
      protocol = recipient.endpoint_conf.syslog_protocol, -- tcp or udp
      host = recipient.endpoint_conf.syslog_host,
      port = recipient.endpoint_conf.syslog_port,
      syslog_alert_format = recipient.endpoint_conf.syslog_alert_format
   }

   if isEmptyString(settings.host) then
      settings.host = nil
   else
      if settings.protocol == nil or settings.protocol ~= 'tcp' then
	 settings.protocol = 'udp'
      end
      if settings.port == nil then
	 settings.port = 514
      else
	 settings.port = tonumber(settings.port)
      end
   end

   return settings
end

-- ##############################################

-- @brief Returns the desided formatted output for recipient params
function syslog.format_recipient_params(recipient_params)
   return string.format("(%s)", syslog.name)
end

-- ##############################################

function syslog.sendMessage(settings, notif, severity)
   local syslog_severity = alert_consts.alertLevelToSyslogLevel(alert_consts.alertSeverityRaw(severity))
   local syslog_format = settings.syslog_alert_format
   local msg

   if syslog_format and syslog_format == "json" then
      msg = json.encode(notif)
   elseif syslog_format and syslog_format == "ecs" then
      if ntop.isEnterpriseM() then
	 package.path = dirs.installdir .. "/pro/scripts/lua/modules/?.lua;" .. package.path
	 local ecs_format = require "ecs_format"
	 msg = json.encode(ecs_format.format(notif))
      else
	 return false
      end
   else -- syslog_format == "plaintext" or "plaintextrfc"
      -- prepare a plaintext message
      msg = alert_utils.formatAlertNotification(notif, {
						   nohtml = true,
						   show_severity = true,
						   show_entity = true})
   end

   if settings.host == nil then
      ntop.syslog(msg, syslog_severity)
   else

      local facility = 14 -- log alert
      local level = syslog_severity
      local prio = (facility * 8) + level
      local date = format_utils.formatEpoch(notif.alert_tstamp) -- "2020-11-09 18:00:00"
      local iso_time = format_utils.formatEpochISO8601(notif.alert_tstamp)
      local host_info = ntop.getHostInformation()
      local host = host_info.ip
      local tag = "ntopng"
      local info = ntop.getInfo()
      local pid = info.pid

      if syslog_format and syslog_format == "plaintextrfc" then
         -- RFC5424 Format:
         -- <PRIO>VERSION ISOTIMESTAMP HOSTNAME APPLICATION PID MESSAGEID MSG
         -- Example:
         -- <113>1 2020-11-19T18:31:21.003Z 192.168.1.1 ntopng 21365 ID1 -
         msg = "<"..prio..">1 "..iso_time.." "..host.." "..tag.." "..pid.." - - "..msg
      else
         -- Unix Format:
         -- <PRIO>DATE TIME DEVICE APPLICATION[PID]: MSG
         -- Example:
         -- <113>09/11/2020 18:31:21 192.168.1.1 ntopng[21365]: ...  
         msg = "<"..prio..">"..date.." "..host.." "..tag.."["..pid.."]: "..msg
      end

      if settings.protocol == 'tcp' then
         ntop.send_tcp_data(settings.host, settings.port, msg.."\n", 1 --[[ timeout (msec) --]] )
      else
         ntop.send_udp_data(settings.host, settings.port, msg)
      end
   end

   return true
end

-- ##############################################

-- Dequeue alerts from a recipient queue for sending notifications
function syslog.dequeueRecipientAlerts(recipient, budget, high_priority)
   local settings = readSettings(recipient)
   local notifications = {}

   for i = 1, budget do
      local notification = ntop.recipient_dequeue(recipient.recipient_id, high_priority)
      if notification then
	 notifications[#notifications + 1] = notification
      else
	 break
      end
   end

   if not notifications or #notifications == 0 then
      return {success = true, more_available = false}
   end

   -- Most recent notifications first
   for _, notification in ipairs(notifications) do
      local notif = notification and json.decode(notification)

      if notif then
	 syslog.sendMessage(settings, notif, notif.alert_severity)
      end
   end

   return {success = true,  more_available = true}
end

-- ##############################################

function syslog.runTest(recipient)
   local settings = readSettings(recipient)

   local now = os.time()
   local notif = {
      alert_tstamp = now,
      alert_entity = alert_consts.alert_entities.test.entity_id,
      alert_severity = alert_consts.alert_severities.info.severity_id
   }

   local success = syslog.sendMessage(settings, notif, alert_consts.alert_severities.info.severity_id)

   local message_info = i18n("prefs.syslog_sent_successfully")
   return success, message_info
end

-- ##############################################

return syslog
