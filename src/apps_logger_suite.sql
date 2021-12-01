--------------------------------------------------------
--  DDL for Table LOGGER_LOGS
--------------------------------------------------------

  CREATE TABLE "LOGGER_LOGS" 
   (	"ID" NUMBER, 
	"LOGGER_LEVEL" NUMBER, 
	"TEXT" VARCHAR2(4000 BYTE), 
	"TIME_STAMP" TIMESTAMP (6), 
	"SCOPE" VARCHAR2(1000 BYTE), 
	"MODULE" VARCHAR2(100 BYTE), 
	"ACTION" VARCHAR2(100 BYTE), 
	"USER_NAME" VARCHAR2(255 BYTE), 
	"CLIENT_IDENTIFIER" VARCHAR2(255 BYTE), 
	"CALL_STACK" VARCHAR2(4000 BYTE), 
	"UNIT_NAME" VARCHAR2(255 BYTE), 
	"LINE_NO" VARCHAR2(100 BYTE), 
	"SCN" NUMBER, 
	"EXTRA" CLOB, 
	"SID" NUMBER, 
	"CLIENT_INFO" VARCHAR2(64 BYTE)
   ) ;
--------------------------------------------------------
--  DDL for Index LOGGER_LOGS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "LOGGER_LOGS_PK" ON "LOGGER_LOGS" ("ID") 
  ;
--------------------------------------------------------
--  DDL for Index LOGGER_LOGS_IDX1
--------------------------------------------------------

  CREATE INDEX "LOGGER_LOGS_IDX1" ON "LOGGER_LOGS" ("TIME_STAMP", "LOGGER_LEVEL") 
  ;
--------------------------------------------------------
--  Constraints for Table LOGGER_LOGS
--------------------------------------------------------

  ALTER TABLE "LOGGER_LOGS" ADD CONSTRAINT "LOGGER_LOGS_LVL_CK" CHECK (logger_level in (1,2,4,8,16,32,64,128)) ENABLE;
  ALTER TABLE "LOGGER_LOGS" ADD CONSTRAINT "LOGGER_LOGS_PK" PRIMARY KEY ("ID")
  USING INDEX  ENABLE;
  ALTER TABLE "LOGGER_LOGS" MODIFY ("LOGGER_LEVEL" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS" MODIFY ("TIME_STAMP" NOT NULL ENABLE);

--------------------------------------------------------
--  DDL for Sequence LOGGER_LOGS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "LOGGER_LOGS_SEQ"  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 3501 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;



--------------------------------------------------------
--  DDL for View LOGGER_LOGS_5_MIN
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "LOGGER_LOGS_5_MIN" ("ID", "LOGGER_LEVEL", "TEXT", "TIME_STAMP", "SCOPE", "MODULE", "ACTION", "USER_NAME", "CLIENT_IDENTIFIER", "CALL_STACK", "UNIT_NAME", "LINE_NO", "SCN", "EXTRA", "SID", "CLIENT_INFO") AS 
  select "ID","LOGGER_LEVEL","TEXT","TIME_STAMP","SCOPE","MODULE","ACTION","USER_NAME","CLIENT_IDENTIFIER","CALL_STACK","UNIT_NAME","LINE_NO","SCN","EXTRA","SID","CLIENT_INFO" 
      from logger_logs 
	 where time_stamp > systimestamp - (5/1440)
;

--------------------------------------------------------
--  DDL for View LOGGER_LOGS_60_MIN
--------------------------------------------------------

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "LOGGER_LOGS_60_MIN" ("ID", "LOGGER_LEVEL", "TEXT", "TIME_STAMP", "SCOPE", "MODULE", "ACTION", "USER_NAME", "CLIENT_IDENTIFIER", "CALL_STACK", "UNIT_NAME", "LINE_NO", "SCN", "EXTRA", "SID", "CLIENT_INFO") AS 
  select "ID","LOGGER_LEVEL","TEXT","TIME_STAMP","SCOPE","MODULE","ACTION","USER_NAME","CLIENT_IDENTIFIER","CALL_STACK","UNIT_NAME","LINE_NO","SCN","EXTRA","SID","CLIENT_INFO" 
      from logger_logs 
	 where time_stamp > systimestamp - (1/24)
;

--------------------------------------------------------
--  DDL for Table LOGGER_PREFS
--------------------------------------------------------

  CREATE TABLE "LOGGER_PREFS" 
   (	"PREF_NAME" VARCHAR2(255 BYTE), 
	"PREF_VALUE" VARCHAR2(255 BYTE), 
	"PREF_TYPE" VARCHAR2(30 BYTE)
   ) ;
--------------------------------------------------------
--  DDL for Index LOGGER_PREFS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "LOGGER_PREFS_PK" ON "LOGGER_PREFS" ("PREF_TYPE", "PREF_NAME") 
  ;


--------------------------------------------------------
--  DDL for Sequence LOGGER_APX_ITEMS_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "LOGGER_APX_ITEMS_SEQ"  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;



--------------------------------------------------------
--  DDL for Table LOGGER_LOGS_APEX_ITEMS
--------------------------------------------------------

  CREATE TABLE "LOGGER_LOGS_APEX_ITEMS" 
   (	"ID" NUMBER, 
	"LOG_ID" NUMBER, 
	"APP_SESSION" NUMBER, 
	"ITEM_NAME" VARCHAR2(1000 BYTE), 
	"ITEM_VALUE" CLOB
   ) ;
--------------------------------------------------------
--  DDL for Index LOGGER_LOGS_APX_ITMS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "LOGGER_LOGS_APX_ITMS_PK" ON "LOGGER_LOGS_APEX_ITEMS" ("ID") 
  ;
--------------------------------------------------------
--  DDL for Index LOGGER_APEX_ITEMS_IDX1
--------------------------------------------------------

  CREATE INDEX "LOGGER_APEX_ITEMS_IDX1" ON "LOGGER_LOGS_APEX_ITEMS" ("LOG_ID") 
  ;
--------------------------------------------------------
--  DDL for Trigger BIU_LOGGER_APEX_ITEMS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "BIU_LOGGER_APEX_ITEMS" 
  before insert or update on logger_logs_apex_items
for each row
begin
  :new.id := logger_apx_items_seq.nextval;
end;

/
ALTER TRIGGER "BIU_LOGGER_APEX_ITEMS" ENABLE;
--------------------------------------------------------
--  Constraints for Table LOGGER_LOGS_APEX_ITEMS
--------------------------------------------------------

  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("ID" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("LOG_ID" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("APP_SESSION" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" MODIFY ("ITEM_NAME" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" ADD CONSTRAINT "LOGGER_LOGS_APX_ITMS_PK" PRIMARY KEY ("ID")
  USING INDEX  ENABLE;
--------------------------------------------------------
--  Ref Constraints for Table LOGGER_LOGS_APEX_ITEMS
--------------------------------------------------------

  ALTER TABLE "LOGGER_LOGS_APEX_ITEMS" ADD CONSTRAINT "LOGGER_LOGS_APX_ITMS_FK" FOREIGN KEY ("LOG_ID")
	  REFERENCES "LOGGER_LOGS" ("ID") ON DELETE CASCADE ENABLE;





--------------------------------------------------------
--  DDL for Package apps_logger
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE apps_logger AS 
    -- TYPES
  type rec_param is record(
    name varchar2(255),
    val varchar2(4000));

  type tab_param is table of rec_param index by binary_integer;

  type rec_logger_log is record(
    id logger_logs.id%type,
    logger_level logger_logs.logger_level%type
  );

  -- Custom error code to reraise errors without re-logging them
  g_logger_reraise_error_code constant integer := -20654;

  g_context_name constant varchar2(35) := substr(sys_context('USERENV','CURRENT_SCHEMA'),1,23)||'_LOGCTX';

  gc_empty_tab_param tab_param;

  g_pref_type_logger constant logger_prefs.pref_type%type := 'LOGGER';

  g_off constant number := 0;
  g_permanent constant number := 1;
	g_error constant number := 2;
	g_warning constant number := 4;
	g_information constant number := 8;
  g_debug constant number := 16;
	g_timing constant number := 32;
  g_sys_context constant number := 64;
  g_apex constant number := 128;

  g_off_name constant varchar2(30) := 'OFF';
  g_permanent_name constant varchar2(30) := 'PERMANENT';
  g_error_name constant varchar2(30) := 'ERROR';
  g_warning_name constant varchar2(30) := 'WARNING';
  g_information_name constant varchar2(30) := 'INFORMATION';
  g_debug_name constant varchar2(30) := 'DEBUG';
  g_timing_name constant varchar2(30) := 'TIMING';
  g_sys_context_name constant varchar2(30) := 'SYS_CONTEXT';
  g_apex_name constant varchar2(30) := 'APEX';

  g_apex_item_type_all constant varchar2(30) := 'ALL'; -- Application items and page items
  g_apex_item_type_app constant varchar2(30) := 'APP'; -- All application items
  g_apex_item_type_page constant varchar2(30) := 'PAGE'; -- All page items

  procedure log_error(
    p_text          in varchar2 default null,
    p_scope         in varchar2 default null,
    p_extra         in clob default null,
    p_params        in tab_param default apps_logger.gc_empty_tab_param,
    p_reraise       in boolean default false);

  function log_error(
    p_text          in varchar2 default null,
    p_scope         in varchar2 default null,
    p_extra         in clob default null,
    p_params        in tab_param default apps_logger.gc_empty_tab_param,
    p_reraise       in boolean default false) RETURN NUMBER;

  procedure log_apex_error(
    p_text in varchar2 default 'Error in APEX',
    p_scope in logger_logs.scope%type default null,
    p_extra  in clob default null,
    p_item_type in varchar2 default apps_logger.g_apex_item_type_all,
    p_log_null_items in boolean default true);

  function log_apex_error(
    p_text in varchar2 default 'Error in APEX',
    p_scope in logger_logs.scope%type default null,
    p_extra  in clob default null,
    p_item_type in varchar2 default apps_logger.g_apex_item_type_all,
    p_log_null_items in boolean default true) RETURN NUMBER;

  procedure log_permanent(
    p_text    in varchar2,
    p_scope   in varchar2 default null,
    p_extra   in clob default null,
    p_params  in tab_param default apps_logger.gc_empty_tab_param);

  procedure log_warning(
    p_text    in varchar2,
    p_scope   in varchar2 default null,
    p_extra   in clob default null,
    p_params  in tab_param default apps_logger.gc_empty_tab_param);

  procedure log_warn(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param);

  procedure log_information(
    p_text    in varchar2,
    p_scope   in varchar2 default null,
    p_extra   in clob default null,
    p_params  in tab_param default apps_logger.gc_empty_tab_param);

  procedure log_info(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param);

  procedure log(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param);

  procedure log_apex_items(
    p_text in varchar2 default 'Log APEX Items',
    p_scope in logger_logs.scope%type default null,
    p_item_type in varchar2 default apps_logger.g_apex_item_type_all,
    p_log_null_items in boolean default true,
    p_level in logger_logs.logger_level%type default null);

  function get_pref(
    p_pref_name in logger_prefs.pref_name%type,
    p_pref_type in logger_prefs.pref_type%type default apps_logger.g_pref_type_logger)
    return varchar2
    result_cache;

  -- #103
  procedure set_pref(
    p_pref_type in logger_prefs.pref_type%type,
    p_pref_name in logger_prefs.pref_name%type,
    p_pref_value in logger_prefs.pref_value%type);

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in varchar2);

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in number);

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in date);

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in timestamp);

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in timestamp with time zone);

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in timestamp with local time zone);

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in boolean);

  function ok_to_log(p_level in number)
    return boolean
    result_cache;  

  function ok_to_log(p_level in varchar2)
    return boolean;

  procedure set_level(
    p_level in varchar2 default apps_logger.g_debug_name,
    p_client_id in varchar2 default null,
    p_include_call_stack in varchar2 default null,
    p_client_id_expire_hours in number default null
  );

  procedure time_start(
		p_unit in varchar2,
    p_log_in_table in boolean default true);

	procedure time_stop(
		p_unit in varchar2,
    p_scope in varchar2 default null);

  function time_stop(
    p_unit in varchar2,
    p_scope in varchar2 default null,
    p_log_in_table in boolean default true)
    return varchar2;

  function time_stop_seconds(
    p_unit in varchar2,
    p_scope in varchar2 default null,
    p_log_in_table in boolean default true)
    return number;

  procedure time_reset;

  procedure purge(
		p_purge_after_days in varchar2 default null,
		p_purge_min_level	in varchar2	default null);

  procedure purge(
    p_purge_after_days in number default null,
    p_purge_min_level in number);

END apps_logger;
/


--------------------------------------------------------
--  DDL for Package Body apps_logger
--------------------------------------------------------

  create or replace PACKAGE BODY apps_logger AS
  gc_line_feed constant varchar2(1) := chr(10);
  gc_cflf constant varchar2(2) := chr(13)||chr(10);
  gc_date_format constant varchar2(255) := 'DD-MON-YYYY HH24:MI:SS';
  gc_timestamp_format constant varchar2(255) := gc_date_format || ':FF';
  gc_timestamp_tz_format constant varchar2(255) := gc_timestamp_format || ' TZR';

  gc_pref_level constant logger_prefs.pref_name%type := 'LEVEL';
  gc_pref_include_call_stack constant logger_prefs.pref_name%type := 'INCLUDE_CALL_STACK';
  gc_pref_protect_admin_procs constant logger_prefs.pref_name%type := 'PROTECT_ADMIN_PROCS';
  gc_pref_install_schema constant logger_prefs.pref_name%type := 'INSTALL_SCHEMA';
  gc_pref_purge_after_days constant logger_prefs.pref_name%type := 'PURGE_AFTER_DAYS';
  gc_pref_purge_min_level constant logger_prefs.pref_name%type := 'PURGE_MIN_LEVEL';
  gc_pref_logger_version constant logger_prefs.pref_name%type := 'LOGGER_VERSION';
  gc_pref_client_id_expire_hours constant logger_prefs.pref_name%type := 'PREF_BY_CLIENT_ID_EXPIRE_HOURS';
  gc_pref_logger_debug constant logger_prefs.pref_name%type := 'LOGGER_DEBUG';
  gc_pref_plugin_fn_error constant logger_prefs.pref_name%type := 'PLUGIN_FN_ERROR';

  gc_ctx_attr_include_call_stack constant varchar2(18) := 'include_call_stack';

  type ts_array is table of timestamp index by varchar2(100);

  g_log_id number;
  g_proc_start_times ts_array;
  g_running_timers pls_integer := 0;

  function tochar(
    p_val in number)
    return varchar2
  as
  begin
    return to_char(p_val);
  end tochar;

  function tochar(
    p_val in date)
    return varchar2
  as
  begin
    return to_char(p_val, gc_date_format);
  end tochar;

  function tochar(
    p_val in timestamp)
    return varchar2
  as
  begin
    return to_char(p_val, gc_timestamp_format);
  end tochar;

  function tochar(
    p_val in timestamp with time zone)
    return varchar2
  as
  begin
    return to_char(p_val, gc_timestamp_tz_format);
  end tochar;

  function tochar(
    p_val in timestamp with local time zone)
    return varchar2
  as
  begin
    return to_char(p_val, gc_timestamp_tz_format);
  end tochar;

  -- #119: Return null for null booleans
  function tochar(
    p_val in boolean)
    return varchar2
  as
  begin
    return case p_val when true then 'TRUE' when false then 'FALSE' else null end;
  end tochar;


  procedure assert(
    p_condition in boolean,
    p_message in varchar2)
  as
  begin
      if not p_condition or p_condition is null then
        raise_application_error(-20000, p_message);
      end if;
  end assert;

  function is_number(p_str in varchar2)
    return boolean
  as
    l_num number;
  begin
    l_num := to_number(p_str);
    return true;
  exception
    when others then
      return false;
  end is_number;

  function convert_level_char_to_num(
    p_level in varchar2)
    return number
  is
    l_level         number;
  begin
    $if $$no_op $then
      return null;
    $else
      case p_level
        when g_off_name then l_level := g_off;
        when g_permanent_name then l_level := g_permanent;
        when g_error_name then l_level := g_error;
        when g_warning_name then l_level := g_warning;
        when g_information_name then l_level := g_information;
        when g_debug_name then l_level := g_debug;
        when g_timing_name then l_level := g_timing;
        when g_sys_context_name then l_level := g_sys_context;
        when g_apex_name then l_level := g_apex;
        else l_level := -1;
      end case;
    $end

    return l_level;
  end convert_level_char_to_num;

  function convert_level_num_to_char(
    p_level in number)
    return varchar2
  is
    l_return varchar2(255);
  begin
      l_return :=
        case p_level
          when g_off then g_off_name
          when g_permanent then g_permanent_name
          when g_error then g_error_name
          when g_warning then g_warning_name
          when g_information then g_information_name
          when g_debug then g_debug_name
          when g_timing then g_timing_name
          when g_sys_context then g_sys_context_name
          when g_apex then g_apex_name
          else null
        end;

    return l_return;
  end convert_level_num_to_char;

  function get_level_number
    return number
    $if $$rac_lt_11_2 $then
      $if not dbms_db_version.ver_le_10_2 $then
        result_cache relies_on (logger_prefs, logger_prefs_by_client_id)
      $end
    $end
  is
    l_level number;
    l_level_char varchar2(50);

  begin
      $if $$logger_debug $then
        dbms_output.put_line(l_scope || ': selecting logger_level');
      $end

      l_level := convert_level_char_to_num(apps_logger.get_pref(apps_logger.gc_pref_level));

      return l_level;
  end get_level_number;

  procedure ins_logger_logs(
    p_logger_level in logger_logs.logger_level%type,
    p_text in varchar2 default null, -- Not using type since want to be able to pass in 32767 characters
    p_scope in logger_logs.scope%type default null,
    p_call_stack in logger_logs.call_stack%type default null,
    p_unit_name in logger_logs.unit_name%type default null,
    p_line_no in logger_logs.line_no%type default null,
    p_extra in logger_logs.extra%type default null,
    po_id out nocopy logger_logs.id%type
    )
  as
    pragma autonomous_transaction;

    l_id logger_logs.id%type;
    l_text varchar2(32767) := p_text;
    l_extra logger_logs.extra%type := p_extra;
    l_tmp_clob clob;

  begin
      -- Using select into to support version older than 11gR1 (see Issue 26)
      select logger_logs_seq.nextval
      into po_id
      from dual;

      -- 2.1.0: If text is > 4000 characters, it will be moved to the EXTRA column (Issue 17)
      $if $$large_text_column $then -- Only check for moving to Clob if small text column
        -- Don't do anything since column supports large text
      $else
        if lengthb(l_text) > 4000 then -- #109 Using lengthb for multibyte characters
          if l_extra is null then
            l_extra := l_text;
          else
            -- Using temp clob for performance purposes: http://www.talkapex.com/2009/06/how-to-quickly-append-varchar2-to-clob.html
            l_tmp_clob := gc_line_feed || gc_line_feed || '*** Content moved from TEXT column ***' || gc_line_feed;
            l_extra := l_extra || l_tmp_clob;
            l_tmp_clob := l_text;
            l_extra := l_extra || l_text;
          end if; -- l_extra is not null

          l_text := 'Text moved to EXTRA column';
        end if; -- length(l_text)
      $end

      insert into logger_logs(
        id, logger_level, text,
        time_stamp, scope, module,
        action,
        user_name,
        client_identifier,
        call_stack, unit_name, line_no ,
        scn,
        extra,
        sid,
        client_info
        )
       values(
         po_id, p_logger_level, l_text,
         systimestamp, lower(p_scope), sys_context('userenv','module'),
         sys_context('userenv','action'),
         nvl($if $$apex $then apex_application.g_user $else user $end,user),
         sys_context('userenv','client_identifier'),
         p_call_stack, upper(p_unit_name), p_line_no,
         null,
         l_extra,
         to_number(sys_context('userenv','sid')),
         sys_context('userenv','client_info')
         );

    commit;
  end ins_logger_logs;


  function get_param_clob(p_params in apps_logger.tab_param)
    return clob
  as
    l_return clob;
    l_no_vars constant varchar2(255) := 'No params defined';
    l_index pls_integer;
  begin
      -- Generate line feed delimited list
      if p_params.count > 0 then
        -- Using while true ... option allows for unordered param list
        l_index := p_params.first;
        while true loop
          l_return := l_return || p_params(l_index).name || ': ' || p_params(l_index).val;

          l_index := p_params.next(l_index);

          if l_index is null then
            exit;
          else
            l_return := l_return || gc_line_feed;
          end if;
        end loop;

      else
        -- No Parameters
        l_return := l_no_vars;
      end if;

      return l_return;
  end get_param_clob;

  function set_extra_with_params(
    p_extra in logger_logs.extra%type,
    p_params in tab_param
  )
    return logger_logs.extra%type
  as
    l_extra logger_logs.extra%type;
  begin
      if p_params.count = 0 then
        return p_extra;
      else
        l_extra := p_extra || gc_line_feed || gc_line_feed || '*** Parameters ***' || gc_line_feed || gc_line_feed || get_param_clob(p_params => p_params);
      end if;

      return l_extra;

  end set_extra_with_params;

  procedure get_debug_info(
    p_callstack in clob,
    o_unit out varchar2,
    o_lineno out varchar2 )
  as
    --
    l_callstack varchar2(10000) := p_callstack;
  begin
      l_callstack := substr( l_callstack, instr( l_callstack, chr(10), 1, 5 )+1 );
      l_callstack := substr( l_callstack, 1, instr( l_callstack, chr(10), 1, 1 )-1 );
      l_callstack := trim( substr( l_callstack, instr( l_callstack, ' ' ) ) );
      o_lineno := substr( l_callstack, 1, instr( l_callstack, ' ' )-1 );
      o_unit := trim(substr( l_callstack, instr( l_callstack, ' ', -1, 1 ) ));
  end get_debug_info;

  function reduced_call_stack return varchar2 
  is
    l_call_stack varchar(4000);
  begin
    if utl_call_stack.dynamic_depth > 2 then
      l_call_stack := '****** Call Stack Start ******';

      l_call_stack := l_call_stack || gc_line_feed || 'Depth     Lexical   Line      Owner     Edition   Name';
      l_call_stack := l_call_stack || gc_line_feed || '.         Depth     Number';
      l_call_stack := l_call_stack || gc_line_feed || '--------- --------- --------- --------- --------- --------------------';

      for i in 3..utl_call_stack.dynamic_depth loop
        l_call_stack := l_call_stack || gc_line_feed || 
              RPAD(i, 10) ||
              RPAD(UTL_CALL_STACK.lexical_depth(i), 10) ||
              RPAD(TO_CHAR(UTL_CALL_STACK.unit_line(i),'99'), 10) ||
              RPAD(NVL(UTL_CALL_STACK.owner(i),' '), 10) ||
              RPAD(NVL(UTL_CALL_STACK.current_edition(i),' '), 10) ||
              UTL_CALL_STACK.concatenate_subprogram(UTL_CALL_STACK.subprogram(i));
      end loop;

      l_call_stack := l_call_stack || gc_line_feed || '****** Call Stack End ******';
    else
      l_call_stack := 'Callstack irrelevant';
    end if;

    return l_call_stack;
  end;

  function include_call_stack
    return boolean
    $if 1=1
      and $$rac_lt_11_2
      and not dbms_db_version.ver_le_10_2
      and ($$no_op is null or not $$no_op) $then
        result_cache relies_on (logger_prefs, logger_prefs_by_client_id)
    $end
  is
    l_call_stack_pref logger_prefs.pref_value%type;
  begin
        l_call_stack_pref := get_pref(apps_logger.gc_pref_include_call_stack);

      if l_call_stack_pref = 'TRUE' then
        return true;
      else
        return false;
      end if;
  end include_call_stack;

  procedure log_internal(
    p_text in varchar2,
    p_log_level in number,
    p_scope in varchar2,
    p_extra in clob default null,
    p_callstack in varchar2 default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param)
  is
    l_proc_name varchar2(100);
    l_lineno varchar2(100);
    l_text varchar2(32767);
    l_callstack varchar2(3000);
    l_extra logger_logs.extra%type;
  begin
      l_text := p_text;

      -- Generate callstack text
      if p_callstack is not null and apps_logger.include_call_stack then
        apps_logger.get_debug_info(
          p_callstack => p_callstack,
          o_unit => l_proc_name,
          o_lineno => l_lineno);

        l_callstack  := regexp_replace(p_callstack,'^.*$','',1,4,'m');
        l_callstack  := regexp_replace(l_callstack,'^.*$','',1,1,'m');
        l_callstack  := ltrim(replace(l_callstack,chr(10)||chr(10),chr(10)),chr(10));

      end if;

      l_extra := set_extra_with_params(p_extra => p_extra, p_params => p_params);

      ins_logger_logs(
        p_unit_name => upper(l_proc_name) ,
        p_scope => p_scope ,
        p_logger_level =>p_log_level,
        p_extra => l_extra,
        p_text =>l_text,
        p_call_stack  =>l_callstack,
        p_line_no => l_lineno,
        po_id => g_log_id);
  end log_internal;

  procedure log_error(
    p_text in varchar2 default null,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param,
    p_reraise in boolean default false)
  is
    l_proc_name varchar2(100);
    l_lineno varchar2(100);
    l_text varchar2(32767);
    l_call_stack varchar2(4000);
    l_extra clob;
    l_error_code integer := SQLCODE;
  begin
      if l_error_code != g_logger_reraise_error_code then
          if ok_to_log(apps_logger.g_error) then
            get_debug_info(
              p_callstack => dbms_utility.format_call_stack,
              o_unit => l_proc_name,
              o_lineno => l_lineno);

            l_call_stack := reduced_call_stack || 
                gc_line_feed || 
                gc_line_feed || dbms_utility.format_error_stack() || 
                gc_line_feed || dbms_utility.format_error_backtrace;

            if p_text is not null then
              l_text := p_text || gc_line_feed || gc_line_feed;
            end if;

            l_text := l_text || dbms_utility.format_error_stack();

            l_extra := set_extra_with_params(p_extra => p_extra, p_params => p_params);

            ins_logger_logs(
              p_unit_name => upper(l_proc_name) ,
              p_scope => p_scope ,
              p_logger_level => apps_logger.g_error,
              p_extra => l_extra,
              p_text => l_text,
              p_call_stack => l_call_stack,
              p_line_no => l_lineno,
              po_id => g_log_id);

          end if; -- ok_to_log
      end if; -- not reraise_error_code

      if p_reraise then
        raise_application_error(
            g_logger_reraise_error_code,
            'Logger reraise error'); 
      end if;
  end log_error;

  function log_error(
    p_text in varchar2 default null,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param,
    p_reraise in boolean default false) return NUMBER
  is
    l_proc_name varchar2(100);
    l_lineno varchar2(100);
    l_text varchar2(32767);
    l_call_stack varchar2(4000);
    l_extra clob;
    l_error_code integer := SQLCODE;
  begin
      if l_error_code != g_logger_reraise_error_code then
          if ok_to_log(apps_logger.g_error) then
            get_debug_info(
              p_callstack => dbms_utility.format_call_stack,
              o_unit => l_proc_name,
              o_lineno => l_lineno);

            l_call_stack := reduced_call_stack || 
                gc_line_feed || 
                gc_line_feed || dbms_utility.format_error_stack() || 
                gc_line_feed || dbms_utility.format_error_backtrace;

            if p_text is not null then
              l_text := p_text || gc_line_feed || gc_line_feed;
            end if;

            l_text := l_text || dbms_utility.format_error_stack();

            l_extra := set_extra_with_params(p_extra => p_extra, p_params => p_params);

            ins_logger_logs(
              p_unit_name => upper(l_proc_name) ,
              p_scope => p_scope ,
              p_logger_level => apps_logger.g_error,
              p_extra => l_extra,
              p_text => l_text,
              p_call_stack => l_call_stack,
              p_line_no => l_lineno,
              po_id => g_log_id);

            return g_log_id;
          else
            return NULL;
          end if; -- ok_to_log
      end if; -- not reraise_error_code

      if p_reraise then
        raise_application_error(
            g_logger_reraise_error_code,
            'Logger reraise error'); 
      end if;
  end log_error;

  procedure log_permanent(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param)
  is
  begin
      if ok_to_log(apps_logger.g_permanent) then
        log_internal(
          p_text => p_text,
          p_log_level => apps_logger.g_permanent,
          p_scope => p_scope,
          p_extra => p_extra,
          p_callstack => dbms_utility.format_call_stack,
          p_params => p_params
        );
      end if;
  end log_permanent;

  procedure log_warning(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param)
  is
  begin
      if ok_to_log(apps_logger.g_warning) then
        log_internal(
          p_text => p_text,
          p_log_level => apps_logger.g_warning,
          p_scope => p_scope,
          p_extra => p_extra,
          p_callstack => dbms_utility.format_call_stack,
          p_params => p_params);
      end if;
  end log_warning;

  procedure log_warn(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param)
  is
  begin
    apps_logger.log_warning(
      p_text => p_text,
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params
    );
  end log_warn;

  procedure log_information(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param)
  is
  begin
      if ok_to_log(apps_logger.g_information) then
        log_internal(
          p_text => p_text,
          p_log_level => apps_logger.g_information,
          p_scope => p_scope,
          p_extra => p_extra,
          p_callstack => dbms_utility.format_call_stack,
          p_params => p_params);
      end if;
  end log_information;

  procedure log_info(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param)
  is
  begin
    apps_logger.log_information(
      p_text => p_text,
      p_scope => p_scope,
      p_extra => p_extra,
      p_params => p_params
    );
  end log_info;

  procedure log(
    p_text in varchar2,
    p_scope in varchar2 default null,
    p_extra in clob default null,
    p_params in tab_param default apps_logger.gc_empty_tab_param)
  is
  begin
      if ok_to_log(apps_logger.g_debug) then
        log_internal(
          p_text => p_text,
          p_log_level => apps_logger.g_debug,
          p_scope => p_scope,
          p_extra => p_extra,
          p_callstack => dbms_utility.format_call_stack,
          p_params => p_params);
      end if;
  end log;

  procedure snapshot_apex_items(
    p_log_id in logger_logs.id%type,
    p_item_type in varchar2,
    p_log_null_items in boolean)
  is
    l_app_session number;
    l_app_id number;
    l_log_null_item_yn varchar2(1);
    l_item_type varchar2(30) := upper(p_item_type);
    l_item_type_page_id number;
  begin
        l_app_session := v('APP_SESSION');
        l_app_id := v('APP_ID');

        l_log_null_item_yn := 'N';
        if p_log_null_items then
          l_log_null_item_yn := 'Y';
        end if;

        if apps_logger.is_number(l_item_type) then
          l_item_type_page_id := to_number(l_item_type);
        end if;

        insert into logger_logs_apex_items(log_id,app_session,item_name,item_value)
        select p_log_id, l_app_session, item_name, item_value
        from (
          -- Application items
          select 1 app_page_seq, 0 page_id, item_name, v(item_name) item_value
          from apex_application_items
          where 1=1
            and application_id = l_app_id
            and l_item_type in (apps_logger.g_apex_item_type_all, apps_logger.g_apex_item_type_app)
          union all
          -- Application page items
          select 2 app_page_seq, page_id, item_name, v(item_name) item_value
          from apex_application_page_items
          where 1=1
            and application_id = l_app_id
            and (
              1=2
              or l_item_type in (apps_logger.g_apex_item_type_all, apps_logger.g_apex_item_type_page)
              or (l_item_type_page_id is not null and l_item_type_page_id = page_id)
            )
          )
        where 1=1
          and (l_log_null_item_yn = 'Y' or item_value is not null)
        order by app_page_seq, page_id, item_name;
  end snapshot_apex_items;

  procedure log_apex_items(
    p_text in varchar2 default 'Log APEX Items',
    p_scope in logger_logs.scope%type default null,
    p_item_type in varchar2 default apps_logger.g_apex_item_type_all,
    p_log_null_items in boolean default true,
    p_level in logger_logs.logger_level%type default null)
  is
    l_error varchar2(4000);
    pragma autonomous_transaction;
  begin
      if ok_to_log(nvl(p_level, apps_logger.g_debug)) then

          log_internal(
            p_text => p_text,
            p_log_level => nvl(p_level, apps_logger.g_apex),
            p_scope => p_scope);

          snapshot_apex_items(
            p_log_id => g_log_id,
            p_item_type => upper(p_item_type),
            p_log_null_items => p_log_null_items);
      end if;
    commit;
  end log_apex_items;


  function log_apex_error(
    p_text in varchar2 default 'Error in APEX',
    p_scope in logger_logs.scope%type default null,
    p_extra  in clob default null,
    p_item_type in varchar2 default apps_logger.g_apex_item_type_all,
    p_log_null_items in boolean default true) RETURN NUMBER
  is
    l_proc_name varchar2(100);
    l_lineno varchar2(100);
    l_text varchar2(32767);
    l_call_stack varchar2(4000);
    l_extra clob;
    l_error_code integer := SQLCODE;
    l_error varchar2(4000);
    pragma autonomous_transaction;
  begin
      if ok_to_log(apps_logger.g_error) then
            get_debug_info(
              p_callstack => dbms_utility.format_call_stack,
              o_unit => l_proc_name,
              o_lineno => l_lineno);

            l_call_stack := reduced_call_stack ||
                gc_line_feed ||
                gc_line_feed || --dbms_utility.format_error_stack() ||
                gc_line_feed || dbms_utility.format_error_backtrace;

            if p_text is not null then
              l_text := p_text || gc_line_feed || gc_line_feed;
            end if;

            l_text := l_text || dbms_utility.format_error_stack();

            ins_logger_logs(
              p_unit_name => upper(l_proc_name) ,
              p_scope => p_scope ,
              p_logger_level => apps_logger.g_error,
              p_extra => p_extra,
              p_text => l_text,
              p_call_stack => l_call_stack,
              p_line_no => l_lineno,
              po_id => g_log_id);


            snapshot_apex_items(
                p_log_id => g_log_id,
                p_item_type => upper(p_item_type),
                p_log_null_items => p_log_null_items);

            commit;
            return g_log_id;
          else
            return NULL;
          end if; -- ok_to_log

  end log_apex_error;


  procedure log_apex_error(
    p_text in varchar2 default 'Error in APEX',
    p_scope in logger_logs.scope%type default null,
    p_extra  in clob default null,
    p_item_type in varchar2 default apps_logger.g_apex_item_type_all,
    p_log_null_items in boolean default true)
  is
    l_id_log NUMBER;
  begin
      l_id_log := log_apex_error(p_text => p_text,
                                p_scope => p_scope,
                                p_extra => p_extra,
                                p_item_type => p_item_type,
                                p_log_null_items => p_log_null_items);
  end log_apex_error;

  function get_pref(
    p_pref_name in logger_prefs.pref_name%type,
    p_pref_type in logger_prefs.pref_type%type default apps_logger.g_pref_type_logger)
    return varchar2
    result_cache relies_on (logger_prefs, logger_prefs_by_client_id)
  is
    l_scope varchar2(30) := 'get_pref';
    l_pref_value logger_prefs.pref_value%type;
    l_pref_name logger_prefs.pref_name%type := upper(p_pref_name);
    l_pref_type logger_prefs.pref_type%type := upper(p_pref_type);
  begin


      select pref_value
      into l_pref_value

          from logger_prefs
          where 1=1
            and pref_name = l_pref_name
            and pref_type = l_pref_type;


      return l_pref_value;

  exception
    when no_data_found then
      return null;
    when others then
      raise;
  end get_pref;

  procedure set_pref(
    p_pref_type in logger_prefs.pref_type%type,
    p_pref_name in logger_prefs.pref_name%type,
    p_pref_value in logger_prefs.pref_value%type)
  as
    l_pref_type logger_prefs.pref_type%type := trim(upper(p_pref_type));
    l_pref_name logger_prefs.pref_name%type := trim(upper(p_pref_name));
  begin
      if l_pref_type = apps_logger.g_pref_type_logger then
        raise_application_error(-20001, 'Can not set ' || l_pref_type || '. Reserved for Logger');
      end if;

      merge into logger_prefs p
      using (select l_pref_type pref_type, l_pref_name pref_name, p_pref_value pref_value
             from dual) args
      on ( 1=1
        and p.pref_type = args.pref_type
        and p.pref_name = args.pref_name)
      when matched then
        update
        set p.pref_value =  args.pref_value
      when not matched then
        insert (pref_type, pref_name ,pref_value)
      values
        (args.pref_type, args.pref_name ,args.pref_value);
  end set_pref;

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in varchar2
  )
  as
    l_param apps_logger.rec_param;
  begin
      l_param.name := p_name;
      l_param.val := p_val;
      p_params(p_params.count + 1) := l_param;
  end append_param;

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in number)
  as
    l_param apps_logger.rec_param;
  begin
      apps_logger.append_param(p_params => p_params, p_name => p_name, p_val => apps_logger.tochar(p_val => p_val));
  end append_param;

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in date)
  as
    l_param apps_logger.rec_param;
  begin
      apps_logger.append_param(p_params => p_params, p_name => p_name, p_val => apps_logger.tochar(p_val => p_val));
  end append_param;

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in timestamp)
  as
    l_param apps_logger.rec_param;
  begin
      apps_logger.append_param(p_params => p_params, p_name => p_name, p_val => apps_logger.tochar(p_val => p_val));
  end append_param;

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in timestamp with time zone)
  as
    l_param apps_logger.rec_param;
  begin
      apps_logger.append_param(p_params => p_params, p_name => p_name, p_val => apps_logger.tochar(p_val => p_val));
  end append_param;

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in timestamp with local time zone)
  as
    l_param apps_logger.rec_param;
  begin
      apps_logger.append_param(p_params => p_params, p_name => p_name, p_val => apps_logger.tochar(p_val => p_val));
  end append_param;

  procedure append_param(
    p_params in out nocopy apps_logger.tab_param,
    p_name in varchar2,
    p_val in boolean)
  as
    l_param apps_logger.rec_param;
  begin
      apps_logger.append_param(p_params => p_params, p_name => p_name, p_val => apps_logger.tochar(p_val => p_val));
  end append_param;

  function ok_to_log(p_level in number)
    return boolean
    result_cache relies_on (logger_prefs, logger_prefs_by_client_id)

  is
    l_level number;
    l_level_char varchar2(50);

  begin
    l_level := get_level_number;
      if l_level >= p_level then
        return true;
      else
        return false;
      end if;
  end ok_to_log;

  function ok_to_log(p_level in varchar2)
    return boolean
  as
  begin
      return ok_to_log(p_level => convert_level_char_to_num(p_level => p_level));
  end ok_to_log;

  procedure set_level(
    p_level in varchar2 default apps_logger.g_debug_name,
    p_client_id in varchar2 default null,
    p_include_call_stack in varchar2 default null,
    p_client_id_expire_hours in number default null
  )
  is
    l_level varchar2(20);
    l_ctx varchar2(2000);
    l_include_call_stack varchar2(255);
    l_client_id_expire_hours number;

    l_id logger_logs.id%type;
    pragma autonomous_transaction;
  begin
      l_level := replace(upper(p_level),' ');

      if is_number(p_str => l_level) then
        l_level := convert_level_num_to_char(p_level => p_level);
      end if;

      l_include_call_stack := nvl(trim(upper(p_include_call_stack)), get_pref(apps_logger.gc_pref_include_call_stack));

      assert(
          l_level in (g_off_name, g_permanent_name, g_error_name, g_warning_name, g_information_name, g_debug_name, g_timing_name, g_sys_context_name, g_apex_name),
        '"LEVEL" must be one of the following values: ' ||
          g_off_name || ', ' || g_permanent_name || ', ' || g_error_name || ', ' || g_warning_name || ', ' ||
          g_information_name || ', ' || g_debug_name || ', ' || g_timing_name || ', ' ||
          g_sys_context_name || ', ' || g_apex_name );
      assert(l_include_call_stack in ('TRUE', 'FALSE'), 'l_include_call_stack must be TRUE or FALSE');

        l_ctx := 'Host: '||sys_context('USERENV','HOST');
        l_ctx := l_ctx || ', IP: '||sys_context('USERENV','IP_ADDRESS');
        l_ctx := l_ctx || ', TERMINAL: '||sys_context('USERENV','TERMINAL');
        l_ctx := l_ctx || ', OS_USER: '||sys_context('USERENV','OS_USER');
        l_ctx := l_ctx || ', CURRENT_USER: '||sys_context('USERENV','CURRENT_USER');
        l_ctx := l_ctx || ', SESSION_USER: '||sys_context('USERENV','SESSION_USER');


          -- Global settings
          update logger_prefs
          set pref_value = l_level
          where 1=1
            and pref_type = apps_logger.g_pref_type_logger
            and pref_name = apps_logger.gc_pref_level;

        -- Manual insert to ensure that data gets logged, regardless of logger_level
        apps_logger.ins_logger_logs(
          p_logger_level => apps_logger.g_information,
          p_text => 'Log level set to ' || l_level || ' for client_id: ' || nvl(p_client_id, '<global>') || ', include_call_stack=' || l_include_call_stack || ' by ' || l_ctx,
          po_id => l_id);

    commit;
  end set_level;

  procedure time_start(
    p_unit in varchar2,
    p_log_in_table in boolean default true)
  is
    l_proc_name varchar2(100);
    l_text varchar2(4000);
    l_pad varchar2(100);
  begin
      if ok_to_log(apps_logger.g_debug) then
        g_running_timers := g_running_timers + 1;

        if g_running_timers > 1 then
          -- Use 'a' since lpad requires a value to pad
          l_pad := replace(lpad('a',apps_logger.g_running_timers,'>')||' ', 'a', null);
        end if;

        g_proc_start_times(p_unit) := localtimestamp;

        l_text := l_pad||'START TIMER: '||p_unit;

        if p_log_in_table then
          ins_logger_logs(
            p_unit_name => p_unit ,
            p_logger_level => g_timing,
            p_text =>l_text,
            po_id => g_log_id);
        end if;
      end if;
  end time_start;

  procedure time_stop(
    p_unit in varchar2,
    p_scope in varchar2 default null)
  is
    l_time_string varchar2(50);
    l_text varchar2(4000);
    l_pad varchar2(100);
  begin
      if ok_to_log(apps_logger.g_debug) then
        if g_proc_start_times.exists(p_unit) then

          if g_running_timers > 1 then
            -- Use 'a' since lpad requires a value to pad
            l_pad := replace(lpad('a',apps_logger.g_running_timers,'>')||' ', 'a', null);
          end if;

          --l_time_string := rtrim(regexp_replace(systimestamp-(g_proc_start_times(p_unit)),'.+?[[:space:]](.*)','\1',1,0),0);
          -- Function time_stop will decrement the timers and pop the name from the g_proc_start_times array
          l_time_string := time_stop(
            p_unit => p_unit,
            p_log_in_table => false);

          l_text := l_pad||'STOP : '||p_unit ||' - '||l_time_string;

          ins_logger_logs(
            p_unit_name => p_unit,
            p_scope => p_scope ,
            p_logger_level => g_timing,
            p_text =>l_text,
            po_id => g_log_id);
        end if;
      end if;
  end time_stop;

  function time_stop(
    p_unit in varchar2,
    p_scope in varchar2 default null,
    p_log_in_table IN boolean default true)
    return varchar2
  is
    l_time_string varchar2(50);
  begin
      if ok_to_log(apps_logger.g_debug) then
        if g_proc_start_times.exists(p_unit) then

          l_time_string := rtrim(regexp_replace(localtimestamp - (g_proc_start_times(p_unit)),'.+?[[:space:]](.*)','\1',1,0),0);

          g_proc_start_times.delete(p_unit);
          g_running_timers := g_running_timers - 1;

          if p_log_in_table then
            ins_logger_logs(
              p_unit_name => p_unit,
              p_scope => p_scope ,
              p_logger_level => g_timing,
              p_text => l_time_string,
              po_id => g_log_id);
          end if;

          return l_time_string;

        end if;
      end if;
  end time_stop;


  function time_stop_seconds(
    p_unit in varchar2,
    p_scope in varchar2 default null,
    p_log_in_table in boolean default true
    )
    return number
  is
    l_time_string varchar2(50);
    l_seconds number;
    l_interval interval day to second;

  begin
      if ok_to_log(apps_logger.g_debug) then
        if g_proc_start_times.exists(p_unit) then
          l_interval := localtimestamp - (g_proc_start_times(p_unit));
          l_seconds := extract(day from l_interval) * 86400 + extract(hour from l_interval) * 3600 + extract(minute from l_interval) * 60 + extract(second from l_interval);

          g_proc_start_times.delete(p_unit);
          g_running_timers := g_running_timers - 1;

          if p_log_in_table then
            ins_logger_logs(
              p_unit_name => p_unit,
              p_scope => p_scope ,
              p_logger_level => g_timing,
              p_text => l_seconds,
              po_id => g_log_id);
          end if;

          return l_seconds;

        end if;
      end if;
  end time_stop_seconds;

  procedure time_reset
  is
  begin
      if ok_to_log(apps_logger.g_debug) then
        g_running_timers := 0;
        g_proc_start_times.delete;
      end if;
  end time_reset;

  procedure purge(
    p_purge_after_days in number default null,
    p_purge_min_level in number)

  is
      l_purge_after_days number := nvl(p_purge_after_days,get_pref(apps_logger.gc_pref_purge_after_days));
    pragma autonomous_transaction;
  begin

        delete
          from logger_logs
         where logger_level >= p_purge_min_level
           and time_stamp < systimestamp - NUMTODSINTERVAL(l_purge_after_days, 'day')
           and logger_level > g_permanent;
    commit;
  end purge;

  procedure purge(
    p_purge_after_days in varchar2 default null,
    p_purge_min_level in varchar2 default null)

  is
  begin
      purge(
        p_purge_after_days => to_number(p_purge_after_days),
        p_purge_min_level => convert_level_char_to_num(nvl(p_purge_min_level,get_pref(apps_logger.gc_pref_purge_min_level))));
  end purge;

END apps_logger;
/




--------------------------------------------------------
--  DDL for Trigger BIU_LOGGER_PREFS
--------------------------------------------------------

  create or replace EDITIONABLE TRIGGER "BIU_LOGGER_PREFS" 
  before insert or update on logger_prefs
  for each row
begin
    :new.pref_name := upper(:new.pref_name);
    :new.pref_type := upper(:new.pref_type);

    if 1=1
      and :new.pref_type = apps_logger.g_pref_type_logger
      and :new.pref_name = 'LEVEL' then
      :new.pref_value := upper(:new.pref_value);
    end if;

    -- TODO mdsouza: 3.1.1
    -- TODO mdsouza: if removing then decrease indent
    -- $if $$currently_installing is null or not $$currently_installing $then
      -- Since logger.pks may not be installed when this trigger is compiled, need to move some code here
      if 1=1
        and :new.pref_type = apps_logger.g_pref_type_logger
        and :new.pref_name = 'LEVEL'
        and upper(:new.pref_value) not in (apps_logger.g_off_name, apps_logger.g_permanent_name, apps_logger.g_error_name, apps_logger.g_warning_name, apps_logger.g_information_name, apps_logger.g_debug_name, apps_logger.g_timing_name, apps_logger.g_sys_context_name, apps_logger.g_apex_name) then
        raise_application_error(-20000, '"LEVEL" must be one of the following values: ' ||
          apps_logger.g_off_name || ', ' || apps_logger.g_permanent_name || ', ' || apps_logger.g_error_name || ', ' ||
          apps_logger.g_warning_name || ', ' || apps_logger.g_information_name || ', ' || apps_logger.g_debug_name || ', ' ||
          apps_logger.g_timing_name || ', ' || apps_logger.g_sys_context_name || ', ' || apps_logger.g_apex_name);
      end if;

      -- Allow for null to be used for Plugins, then default to NONE
      if 1=1
        and :new.pref_type = apps_logger.g_pref_type_logger
        and :new.pref_name like 'PLUGIN_FN%'
        and :new.pref_value is null then
        :new.pref_value := 'NONE';
      end if;

      -- #103
      -- Only predefined preferences and Custom Preferences are allowed
      -- Custom Preferences must be prefixed with CUST_
      if 1=1
        and :new.pref_type = apps_logger.g_pref_type_logger
        and :new.pref_name not in (
          'GLOBAL_CONTEXT_NAME'
          ,'INCLUDE_CALL_STACK'
          ,'INSTALL_SCHEMA'
          ,'LEVEL'
          ,'LOGGER_DEBUG'
          ,'LOGGER_VERSION'
          ,'PLUGIN_FN_ERROR'
          ,'PREF_BY_CLIENT_ID_EXPIRE_HOURS'
          ,'PROTECT_ADMIN_PROCS'
          ,'PURGE_AFTER_DAYS'
          ,'PURGE_MIN_LEVEL'
        )
      then
        raise_application_error (-20000, 'Setting system level preferences are restricted to a set list.');
      end if;

end;



/
ALTER TRIGGER "BIU_LOGGER_PREFS" ENABLE;
--------------------------------------------------------
--  Constraints for Table LOGGER_PREFS
--------------------------------------------------------

  ALTER TABLE "LOGGER_PREFS" MODIFY ("PREF_VALUE" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS" ADD CONSTRAINT "LOGGER_PREFS_PK" PRIMARY KEY ("PREF_TYPE", "PREF_NAME")
  USING INDEX  ENABLE;
  ALTER TABLE "LOGGER_PREFS" MODIFY ("PREF_TYPE" NOT NULL ENABLE);
  ALTER TABLE "LOGGER_PREFS" ADD CONSTRAINT "LOGGER_PREFS_CK1" CHECK (pref_name = upper(pref_name)) ENABLE;
  ALTER TABLE "LOGGER_PREFS" ADD CONSTRAINT "LOGGER_PREFS_CK2" CHECK (pref_type = upper(pref_type)) ENABLE;


declare
  l_count pls_integer;
  l_job_name user_scheduler_jobs.job_name%type := 'LOGGER_PURGE_JOB';
begin
  
  select count(1)
  into l_count
  from user_scheduler_jobs
  where job_name = l_job_name;
  
  if l_count = 0 then
    dbms_scheduler.create_job(
       job_name => l_job_name,
       job_type => 'PLSQL_BLOCK',
       job_action => 'begin apps_logger.purge; end; ',
       start_date => systimestamp,
       repeat_interval => 'FREQ=DAILY; BYHOUR=1',
       enabled => TRUE,
       comments => 'Purges LOGGER_LOGS using default values defined in logger_prefs.');
  end if;
end;
/

begin
    -- Configure Data
    merge into logger_prefs p
    using (
      select 'PURGE_AFTER_DAYS' pref_name, '7' pref_value from dual union
      select 'PURGE_MIN_LEVEL' pref_name, 'DEBUG' pref_value from dual union
      select 'LEVEL' pref_name, 'DEBUG' pref_value from dual union
      select 'INCLUDE_CALL_STACK' pref_name, 'TRUE' pref_value from dual
      ) d
      on (p.pref_name = d.pref_name)
    when matched then
      update set p.pref_value = p.pref_value
    when not matched then
      insert (p.pref_name,p.pref_value, p.pref_type)
      values (d.pref_name,d.pref_value, 'LOGGER');
end;
/
