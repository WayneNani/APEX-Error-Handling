CREATE TABLE error_lookup
    (
        error_code NUMBER,
        error_message VARCHAR2(300),
        application_id NUMBER,
        page_id NUMBER,
        log_level NUMBER DEFAULT 2 NOT NULL
    )
/

CREATE UNIQUE INDEX error_lookup_app_id_uindex ON error_lookup (error_code, application_id, page_id)
/