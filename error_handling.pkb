CREATE PACKAGE BODY error_handling AS
    gc_scope_prefix CONSTANT VARCHAR2(31) := lower($$plsql_unit) || '.';
    -- ID of the application holding all the error messages
    gc_message_handling_application CONSTANT NUMBER := 122;
        
        
    FUNCTION is_custom_error(error_in apex_error.t_error) RETURN BOOLEAN AS
    BEGIN
        RETURN nvl(instr(error_in.additional_info, gc_custom_error_identifier) > 0, FALSE);
    END is_custom_error;
        
        
    PROCEDURE add_developer_information(error_result_in_out IN OUT apex_error.t_error_result,
                                        error_in                   apex_error.t_error) AS
        l_is_developer_session BOOLEAN;
    BEGIN
        l_is_developer_session := apex_application.g_edit_cookie_session_id IS NOT NULL 
                                  OR v('APP_BUILDER_SESSION') IS NOT NULL;
        IF l_is_developer_session THEN
            error_result_in_out.message :=
                        error_result_in_out.message || '<br><br><b>Developer only:</b> ' || error_in.component.name ||
                        ' ~ ' || error_in.component.type || ' ~ ' || error_in.message;
        END IF;
    END add_developer_information;
        
        
    FUNCTION handle_unexpected_error(error_result_in_out IN OUT apex_error.t_error_result,
                                     error_in                   apex_error.t_error,
                                     page_id_in                 NUMBER,
                                     user_in                    VARCHAR2,
                                     scope_in                   VARCHAR2) RETURN NUMBER AS
        l_log_id NUMBER;
        l_log_text VARCHAR2(32676);
    BEGIN
        l_log_text := get_unexpected_error_log_text(user_in => user_in,
                                                   error_text_in => nvl(error_in.ora_sqlerrm, error_in.message),
                                                   component_name_in => error_in.component.name);
        l_log_id :=
            apps_logger.log_apex_error(p_text => l_log_text,
                                        p_scope => scope_in,
                                        p_item_type => page_id_in);
        error_result_in_out.message := apex_lang.message(p_name => 'DEFAULT_EXCEPTION_TEXT', 
                                                         p0 => l_log_id,
                                                         p_application_id => gc_message_handling_application);
        RETURN l_log_id;
    END handle_unexpected_error;
        
        
    PROCEDURE handle_unexpected_error(error_result_in_out IN OUT apex_error.t_error_result,
                                      error_in                   apex_error.t_error,
                                      page_id_in                 NUMBER,
                                      user_in                    VARCHAR2,
                                      scope_in                   VARCHAR2) AS
        l_log_id NUMBER;
    BEGIN
        l_log_id := handle_unexpected_error(error_result_in_out => error_result_in_out, error_in => error_in,
                                            page_id_in => page_id_in, user_in => user_in, scope_in => scope_in);
    END handle_unexpected_error;
        
        
    PROCEDURE log_error_at_correct_level(log_level_in error_lookup.log_level%TYPE,
                                         log_text_in  VARCHAR2,
                                         scope_in     VARCHAR2) AS
    BEGIN
        CASE log_level_in
            WHEN apps_logger.g_debug
                THEN apps_logger.log(log_text_in, p_scope => scope_in);
            WHEN apps_logger.g_information
                THEN apps_logger.log_information(log_text_in, p_scope => scope_in);
            WHEN apps_logger.g_warning
                THEN apps_logger.log_warning(log_text_in, p_scope => scope_in);
            ELSE apps_logger.log_error(log_text_in, p_scope => scope_in);
        END CASE;
    END log_error_at_correct_level;
        
        
    FUNCTION is_intended_error(error_in apex_error.t_error) RETURN BOOLEAN AS
    BEGIN
        RETURN (error_in.component.type IN ('APEX_APPLICATION_PAGE_VAL',
                                            'APEX_APPLICATION_PAGE_ITEMS',
                                            'APEX_APPL_PAGE_IG_COLUMNS')
                    AND NOT error_in.is_internal_error) 
                OR is_custom_error(error_in => error_in)
                -- a common runtime error like: Access Denied, Session state violation,...
               OR error_in.is_common_runtime_error;
    END is_intended_error;
        
        
    FUNCTION handle_apex_error(p_error IN apex_error.t_error) RETURN apex_error.t_error_result IS
        l_result        apex_error.t_error_result;
        l_app_id        NUMBER        := v('APP_ID');
        l_page_id       NUMBER        := v('APP_PAGE_ID');
        l_current_user  VARCHAR2(300) := v('APP_USER');
        l_scope         VARCHAR2(500) := 'apex_application_' || l_app_id;
        l_error_message g_error_message_rec;
        l_log_text      VARCHAR2(4000);
    BEGIN
        l_result := apex_error.init_error_result(p_error => p_error);
        
        -- Filter out errors you just want to be passed to the user
        IF is_intended_error(error_in => p_error) THEN
            RETURN l_result;
        END IF;
        
        IF p_error.is_internal_error THEN
                
            handle_unexpected_error(error_result_in_out => l_result, 
                                    error_in => p_error,
                                    page_id_in => l_page_id, 
                                    user_in => l_current_user,
                                    scope_in => l_scope);
            l_result.additional_info := NULL;
            
        ELSE
            l_error_message :=
                    most_relevant_error_message(error_code_in => p_error.ora_sqlcode, 
                                                app_id_in => l_app_id,
                                                page_id_in => l_page_id);
            l_result.message := get_message_text(message_identifier_in => l_error_message.message_identifier);
            
            IF l_result.message IS NULL THEN
                -- Error was not in Lookup-Table
                handle_unexpected_error(error_result_in_out => l_result, 
                                        error_in => p_error,
                                        page_id_in => l_page_id, 
                                        user_in => l_current_user,
                                        scope_in => l_scope);
            ELSE
                l_log_text := get_log_text(user_in => l_current_user,
                                           error_text_in => p_error.ora_sqlerrm,
                                           component_name_in => p_error.component.name);
                log_error_at_correct_level(log_level_in => l_error_message.log_level, 
                                           log_text_in => l_log_text,
                                           scope_in => l_scope);
            END IF;
        END IF;
        
        add_developer_information(error_result_in_out => l_result, error_in => p_error);
        
        RETURN l_result;
    END handle_apex_error;
        
        
    FUNCTION most_relevant_error_message(error_code_in NUMBER,
                                         app_id_in     NUMBER,
                                         page_id_in    NUMBER) RETURN g_error_message_rec AS
        l_scope       logger_logs.scope%TYPE := gc_scope_prefix || 'most_relevant_error_message';
        l_params      apps_logger.tab_param;
        l_message_rec g_error_message_rec;
        CURSOR l_relevant_error_messages_cur(ora_error_in NUMBER, app_id_in NUMBER, page_id_in NUMBER) IS
            SELECT error_message, log_level
            FROM error_lookup
            WHERE error_code = ora_error_in
              AND nvl(application_id, app_id_in) = app_id_in
              AND nvl(page_id, page_id_in) = page_id_in
            ORDER BY page_id NULLS LAST, application_id NULLS LAST;
    BEGIN
        OPEN l_relevant_error_messages_cur(ora_error_in => error_code_in, app_id_in => app_id_in,
             page_id_in => page_id_in);
        FETCH l_relevant_error_messages_cur INTO l_message_rec;
        CLOSE l_relevant_error_messages_cur;
        RETURN l_message_rec;
    EXCEPTION
        WHEN OTHERS THEN IF l_relevant_error_messages_cur%ISOPEN THEN
            CLOSE l_relevant_error_messages_cur;
        END IF;
        apps_logger.log_error('Error while determining the most relevant error message', l_scope, NULL, l_params);
        RAISE;
    END most_relevant_error_message;
        
        
    PROCEDURE add_error(message_in          VARCHAR2,
                        additional_info_in  VARCHAR2 DEFAULT NULL,
                        display_location_in VARCHAR2 DEFAULT apex_error.c_inline_in_notification) AS
    BEGIN
        apex_error.add_error(p_message => message_in,
                             p_additional_info => additional_info_in || gc_custom_error_identifier,
                             p_display_location => nvl(display_location_in, apex_error.c_inline_in_notification));
    END add_error;
        
        
    FUNCTION get_message_text(message_identifier_in VARCHAR2,
                              language_in VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 AS
    BEGIN
        RETURN apex_lang.message(p_name => message_identifier_in,
                                 p_application_id => gc_message_handling_application,
                                 p_lang => language_in);
    END get_message_text;
        
        
    FUNCTION get_log_text(user_in VARCHAR2,
                          error_text_in VARCHAR2,
                          component_name_in VARCHAR2) RETURN VARCHAR2 AS
    BEGINCREATE PACKAGE BODY "ERROR_HANDLING" AS
    gc_scope_prefix CONSTANT VARCHAR2(31) := lower($$plsql_unit) || '.';
    -- ID of the application holding all the error messages
    gc_message_handling_application CONSTANT NUMBER := 122;
        
        
    FUNCTION is_custom_error(error_in apex_error.t_error) RETURN BOOLEAN AS
    BEGIN
        RETURN nvl(instr(error_in.additional_info, gc_custom_error_identifier) > 0, FALSE);
    END is_custom_error;
        
        
    PROCEDURE add_developer_information(error_result_in_out IN OUT apex_error.t_error_result,
                                        error_in                   apex_error.t_error) AS
        l_is_developer_session BOOLEAN;
    BEGIN
        l_is_developer_session := apex_application.g_edit_cookie_session_id IS NOT NULL 
                                  OR v('APP_BUILDER_SESSION') IS NOT NULL;
        IF l_is_developer_session THEN
            error_result_in_out.message :=
                        error_result_in_out.message || '<br><br><b>Developer only:</b> ' || error_in.component.name ||
                        ' ~ ' || error_in.component.type || ' ~ ' || error_in.message;
        END IF;
    END add_developer_information;
        
        
    FUNCTION handle_unexpected_error(error_result_in_out IN OUT apex_error.t_error_result,
                                     error_in                   apex_error.t_error,
                                     page_id_in                 NUMBER,
                                     user_in                    VARCHAR2,
                                     scope_in                   VARCHAR2) RETURN NUMBER AS
        l_log_id NUMBER;
        l_log_text VARCHAR2(32676);
    BEGIN
        l_log_text := get_unexpected_error_log_text(user_in => user_in,
                                                   error_text_in => nvl(error_in.ora_sqlerrm, error_in.message),
                                                   component_name_in => error_in.component.name);
        l_log_id :=
            apps_logger.log_apex_error(p_text => l_log_text,
                                        p_scope => scope_in,
                                        p_item_type => page_id_in);
        error_result_in_out.message := apex_lang.message(p_name => 'DEFAULT_EXCEPTION_TEXT', 
                                                         p0 => l_log_id,
                                                         p_application_id => gc_message_handling_application);
        RETURN l_log_id;
    END handle_unexpected_error;
        
        
    PROCEDURE handle_unexpected_error(error_result_in_out IN OUT apex_error.t_error_result,
                                      error_in                   apex_error.t_error,
                                      page_id_in                 NUMBER,
                                      user_in                    VARCHAR2,
                                      scope_in                   VARCHAR2) AS
        l_log_id NUMBER;
    BEGIN
        l_log_id := handle_unexpected_error(error_result_in_out => error_result_in_out, error_in => error_in,
                                            page_id_in => page_id_in, user_in => user_in, scope_in => scope_in);
    END handle_unexpected_error;
        
        
    PROCEDURE log_error_at_correct_level(log_level_in error_lookup.log_level%TYPE,
                                         log_text_in  VARCHAR2,
                                         scope_in     VARCHAR2) AS
    BEGIN
        CASE log_level_in
            WHEN apps_logger.g_debug
                THEN apps_logger.log(log_text_in, p_scope => scope_in);
            WHEN apps_logger.g_information
                THEN apps_logger.log_information(log_text_in, p_scope => scope_in);
            WHEN apps_logger.g_warning
                THEN apps_logger.log_warning(log_text_in, p_scope => scope_in);
            ELSE apps_logger.log_error(log_text_in, p_scope => scope_in);
        END CASE;
    END log_error_at_correct_level;
        
        
    FUNCTION is_intended_error(error_in apex_error.t_error) RETURN BOOLEAN AS
    BEGIN
        RETURN (error_in.component.type IN ('APEX_APPLICATION_PAGE_VAL',
                                            'APEX_APPLICATION_PAGE_ITEMS',
                                            'APEX_APPL_PAGE_IG_COLUMNS')
                    AND NOT error_in.is_internal_error) 
                OR is_custom_error(error_in => error_in)
                -- a common runtime error like: Access Denied, Session state violation,...
               OR error_in.is_common_runtime_error;
    END is_intended_error;
        
        
    FUNCTION handle_apex_error(p_error IN apex_error.t_error) RETURN apex_error.t_error_result IS
        l_result        apex_error.t_error_result;
        l_app_id        NUMBER        := v('APP_ID');
        l_page_id       NUMBER        := v('APP_PAGE_ID');
        l_current_user  VARCHAR2(300) := v('APP_USER');
        l_scope         VARCHAR2(500) := 'apex_application_' || l_app_id;
        l_error_message g_error_message_rec;
        l_log_text      VARCHAR2(4000);
    BEGIN
        l_result := apex_error.init_error_result(p_error => p_error);
        
        -- Filter out errors you just want to be passed to the user
        IF is_intended_error(error_in => p_error) THEN
            RETURN l_result;
        END IF;
        
        IF p_error.is_internal_error THEN
                
            handle_unexpected_error(error_result_in_out => l_result, 
                                    error_in => p_error,
                                    page_id_in => l_page_id, 
                                    user_in => l_current_user,
                                    scope_in => l_scope);
            l_result.additional_info := NULL;
            
        ELSE
            l_error_message :=
                    most_relevant_error_message(error_code_in => p_error.ora_sqlcode, 
                                                app_id_in => l_app_id,
                                                page_id_in => l_page_id);
            l_result.message := get_message_text(message_identifier_in => l_error_message.message_identifier);
            
            IF l_result.message IS NULL THEN
                -- Error was not in Lookup-Table
                handle_unexpected_error(error_result_in_out => l_result, 
                                        error_in => p_error,
                                        page_id_in => l_page_id, 
                                        user_in => l_current_user,
                                        scope_in => l_scope);
            ELSE
                l_log_text := get_log_text(user_in => l_current_user,
                                           error_text_in => p_error.ora_sqlerrm,
                                           component_name_in => p_error.component.name);
                log_error_at_correct_level(log_level_in => l_error_message.log_level, 
                                           log_text_in => l_log_text,
                                           scope_in => l_scope);
            END IF;
        END IF;
        
        add_developer_information(error_result_in_out => l_result, error_in => p_error);
        
        RETURN l_result;
    END handle_apex_error;
        
        
    FUNCTION most_relevant_error_message(error_code_in NUMBER,
                                         app_id_in     NUMBER,
                                         page_id_in    NUMBER) RETURN g_error_message_rec AS
        l_scope       logger_logs.scope%TYPE := gc_scope_prefix || 'most_relevant_error_message';
        l_params      apps_logger.tab_param;
        l_message_rec g_error_message_rec;
        CURSOR l_relevant_error_messages_cur(ora_error_in NUMBER, app_id_in NUMBER, page_id_in NUMBER) IS
            SELECT error_message, log_level
            FROM error_lookup
            WHERE error_code = ora_error_in
              AND nvl(application_id, app_id_in) = app_id_in
              AND nvl(page_id, page_id_in) = page_id_in
            ORDER BY page_id NULLS LAST, application_id NULLS LAST;
    BEGIN
        OPEN l_relevant_error_messages_cur(ora_error_in => error_code_in, app_id_in => app_id_in,
             page_id_in => page_id_in);
        FETCH l_relevant_error_messages_cur INTO l_message_rec;
        CLOSE l_relevant_error_messages_cur;
        RETURN l_message_rec;
    EXCEPTION
        WHEN OTHERS THEN IF l_relevant_error_messages_cur%ISOPEN THEN
            CLOSE l_relevant_error_messages_cur;
        END IF;
        apps_logger.log_error('Error while determining the most relevant error message', l_scope, NULL, l_params);
        RAISE;
    END most_relevant_error_message;
        
        
    PROCEDURE add_error(message_in          VARCHAR2,
                        additional_info_in  VARCHAR2 DEFAULT NULL,
                        display_location_in VARCHAR2 DEFAULT apex_error.c_inline_in_notification) AS
    BEGIN
        apex_error.add_error(p_message => message_in,
                             p_additional_info => additional_info_in || gc_custom_error_identifier,
                             p_display_location => nvl(display_location_in, apex_error.c_inline_in_notification));
    END add_error;
        
        
    FUNCTION get_message_text(message_identifier_in VARCHAR2,
                              language_in VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 AS
    BEGIN
        RETURN apex_lang.message(p_name => message_identifier_in,
                                 p_application_id => gc_message_handling_application,
                                 p_lang => language_in);
    END get_message_text;
        
        
    FUNCTION get_log_text(user_in VARCHAR2,
                          error_text_in VARCHAR2,
                          component_name_in VARCHAR2) RETURN VARCHAR2 AS
    BEGIN
        RETURN apex_string.format(gc_log_text,
                                 user_in,
                                 error_text_in,
                                 component_name_in);
    END get_log_text;
        
        
    FUNCTION get_unexpected_error_log_text(user_in VARCHAR2,
                                          error_text_in VARCHAR2,
                                          component_name_in VARCHAR2) RETURN VARCHAR2 AS
    BEGIN
        RETURN apex_string.format(gc_unexpected_error_log_text,
                                 user_in,
                                 error_text_in,
                                 component_name_in);
    END get_unexpected_error_log_text;
END error_handling;
/


        RETURN apex_string.format(gc_log_text,
                                 user_in,
                                 error_text_in,
                                 component_name_in);
    END get_log_text;
        
        
    FUNCTION get_unexpected_error_log_text(user_in VARCHAR2,
                                          error_text_in VARCHAR2,
                                          component_name_in VARCHAR2) RETURN VARCHAR2 AS
    BEGIN
        RETURN apex_string.format(gc_unexpected_error_log_text,
                                 user_in,
                                 error_text_in,
                                 component_name_in);
    END get_unexpected_error_log_text;
END error_handling;
/

